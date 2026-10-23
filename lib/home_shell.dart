import 'dart:async';

import 'package:flutter/material.dart';
import 'package:receyta/features/achievements/widgets/achievement_watcher.dart';
import 'package:receyta/data/services/auto_backup_service.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/data/services/home_widget_service.dart';
import 'package:receyta/data/services/launcher_shortcuts.dart';
import 'package:receyta/data/services/recipe_link_remote.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/data/sync/sync_coordinator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'package:receyta/domain/engine/recipe_link.dart';
import 'package:receyta/features/folders/screens/recipe_drag.dart';
import 'package:receyta/features/onboarding/controllers/tutorial.dart';
import 'package:receyta/features/onboarding/screens/tutorial_overlay.dart';
import 'package:receyta/features/recipes/screens/receyta_import_flow.dart';
import 'package:receyta/features/planner/screens/month_page.dart';
import 'package:receyta/features/recipes/controllers/recipe_selection.dart';
import 'package:receyta/features/recipes/screens/recipes_page.dart';
import 'package:receyta/features/recipes/screens/selection_bar.dart';
import 'package:receyta/features/settings/controllers/reminder_settings.dart';
import 'package:receyta/features/settings/screens/account_page.dart';
import 'package:receyta/features/shopping/screens/shopping_lists_page.dart';
import 'package:receyta/features/space/controllers/invite_link.dart';
import 'package:receyta/features/subscription/controllers/cloud_access_controller.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/app_snackbar.dart';
import 'package:receyta/widgets/pill_nav_bar.dart';
import 'package:receyta/widgets/sync_status_chip.dart';
import 'package:receyta/widgets/tab_motion.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Casca do app: as quatro seções (§9.2) sob a `PillNavBar` flutuante
/// (§9.8). Semana é placeholder até o bloco F; Compras já é real (E3).
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  int _tab = 0;

  /// Posição (fracionária) da seleção, compartilhada com a `PillNavBar`: a
  /// faixa de páginas segue a mesma mola da pílula e, ao arrastar a barra, o
  /// dedo. Trocar de aba durante o deslize recomeça de onde está, então nunca
  /// dá salto.
  late final TabMotion _motion = TabMotion(vsync: this, count: _pages.length);

  void _select(int i) {
    if (i == _tab) return;
    setState(() {
      _tab = i;
      _visited.add(i);
    });
  }

  /// Enquanto o dedo arrasta a barra, monta as abas que a faixa vai mostrando
  /// (nas trocas por toque só a de destino é montada).
  void _mountNearDrag() {
    if (!_motion.dragging) return;
    final p = _motion.trail;
    final near = {p.floor(), p.ceil()}
        .where((i) => i >= 0 && i < _pages.length && !_visited.contains(i));
    if (near.isEmpty) return;
    setState(() => _visited.addAll(near));
  }

  /// Abas já visitadas: só elas são montadas. O `IndexedStack` mantém vivo
  /// o que está montado (o estado de cada aba se preserva), mas montar as
  /// quatro de cara faz trabalho — e reações a dados — que ninguém vê.
  final _visited = <int>{0};
  StreamSubscription<List<SharedMediaFile>>? _mediaSub;

  @override
  void initState() {
    super.initState();
    // `.receyta` recebido de outro app (D5, RF-06.5): `getInitialMedia`
    // cobre o app fechado sendo aberto pelo anexo; `getMediaStream` cobre o
    // app já aberto recebendo um novo. Os dois passam pelo mesmo canal do
    // `receive_sharing_intent`, nunca pela rota inicial (ver
    // `MainActivity.getInitialRoute` — por isso não navegamos daqui, só
    // importamos e avisamos por snackbar). Best-effort: qualquer falha do
    // plugin (inclusive em teste de widget, sem o canal nativo) não pode
    // travar a home.
    _motion.listenable.addListener(_mountNearDrag);
    _checkInitialShare();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        ref.read(tutorialControllerProvider).startIfNeeded();
        ref.read(reminderSettingsProvider.notifier).syncOnStart();
        ref.read(homeWidgetSyncProvider).start();
        ref.read(autoBackupProvider.notifier).runIfDue();
        ref.read(syncCoordinatorProvider.notifier).start();
        ref.read(launcherShortcutsProvider).start(_onShortcut);
      },
    );
    WidgetsBinding.instance.addObserver(this);
    _mediaSub = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(_handleSharedMedia, onError: (_) {});
  }

  /// Atalho do ícone do app: volta pra home e abre o destino por cima, então
  /// "voltar" sempre cai numa tela conhecida.
  Future<void> _onShortcut(LauncherShortcut shortcut) async {
    if (!mounted) return;
    final router = GoRouter.of(context);
    router.go('/');
    switch (shortcut) {
      case LauncherShortcut.newRecipe:
        router.push('/recipe/new');
      case LauncherShortcut.shopping:
        _select(2);
      case LauncherShortcut.cookLast:
        final recent = await ref
            .read(recipeRepositoryProvider)
            .watchRecent(limit: 1)
            .first;
        if (!mounted) return;
        if (recent.isEmpty) {
          showAppSnackBar(message: 'Você ainda não abriu nenhuma receita.');
          return;
        }
        router.push('/recipe/${recent.first.id}/cook');
    }
  }

  Future<void> _checkInitialShare() async {
    try {
      final media = await ReceiveSharingIntent.instance.getInitialMedia();
      await ReceiveSharingIntent.instance.reset();
      if (!mounted) return;
      _handleSharedMedia(media);
    } catch (_) {
      // Sem plugin nativo (teste de widget) ou qualquer outra falha — segue
      // pra home normal, sem import nenhum.
    }
  }

  /// Não filtra por `file.path` terminar em `.receyta`: confirmado no
  /// aparelho que o WhatsApp às vezes entrega o anexo já cacheado sob o
  /// PRÓPRIO nome interno (`DOC-<data>-WA<n>.bin`), sem a extensão
  /// original — daí o import só "às vezes" funcionar antes desse fix.
  /// Quem decide se é um `.receyta` de verdade é o conteúdo
  /// (`parseReceytaFile`, dentro de `importSharedReceytaFileFlow`), nunca o
  /// nome do arquivo.
  void _handleSharedMedia(List<SharedMediaFile> media) {
    if (media.isEmpty) return;
    final first = media.first;
    if (first.type == SharedMediaType.url) {
      final code = inviteCodeFromLink(first.path);
      if (code != null) {
        GoRouter.of(context).push('/space?code=$code');
        return;
      }
      final token = recipeTokenFromLink(first.path);
      if (token != null) {
        _openRecipeLink(token);
        return;
      }
      final recipe = recipeFromLink(first.path);
      if (recipe != null) {
        GoRouter.of(context).push('/recipe/new', extra: recipe);
        return;
      }
    }
    importSharedReceytaFileFlow(ref, first.path);
  }

  Future<void> _openRecipeLink(String token) async {
    String? fragment;
    var offline = false;
    try {
      fragment = await ref.read(recipeLinkRemoteProvider).fetch(token);
    } catch (_) {
      offline = true;
    }
    if (!mounted) return;
    final recipe = fragment == null ? null : recipeFromFragment(fragment);
    if (recipe == null) {
      showAppSnackBar(
        message: offline
            ? 'Sem conexão. Tente abrir o link de novo quando a internet voltar.'
            : 'Esse link de receita expirou ou não existe mais.',
        variant: AppSnackBarVariant.error,
      );
      return;
    }
    GoRouter.of(context).push('/recipe/new', extra: recipe);
  }

  /// Voltar pro app é um bom momento pra buscar o que mudou em outro aparelho.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(cloudAccessProvider.notifier).refresh());
      ref.read(syncCoordinatorProvider.notifier).onResumed();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mediaSub?.cancel();
    _motion.listenable.removeListener(_mountNearDrag);
    _motion.dispose();
    super.dispose();
  }

  static const _pages = [
    RecipesPage(),
    MonthPage(),
    ShoppingListsPage(),
    AccountPage(),
  ];

  /// As abas lado a lado numa faixa que desliza na horizontal: avançar empurra
  /// a atual pra esquerda e entra a nova pela direita (e vice-versa). Só as
  /// já visitadas existem (ver `_visited`); a que está fora da tela fica
  /// `Offstage` — mantém o estado, mas não ocupa layout nem pintura — e sem
  /// tickers. `HeroMode` só na aba de destino: os `Hero` das outras não
  /// podem voar (ver nota antiga do `IndexedStack`).
  Widget _buildPages() {
    return AnimatedBuilder(
      animation: _motion.listenable,
      builder: (context, _) {
        final position = _motion.trail.clamp(0.0, _pages.length - 1.0);
        return Stack(
          fit: StackFit.expand,
          children: [
            for (final (i, page) in _pages.indexed)
              if (_visited.contains(i))
                Positioned.fill(
                  key: ValueKey(i),
                  child: _TabSlot(
                    offset: i - position,
                    heroes: i == _tab,
                    child: page,
                  ),
                ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final items = [
      PillNavItem(
        icon: Icons.menu_book_rounded,
        label: 'Receitas',
        color: colors.coral,
        motif: TileMotif.arco,
      ),
      PillNavItem(
        icon: Icons.calendar_today_rounded,
        label: 'Agenda',
        color: colors.violet,
        motif: TileMotif.meiaLua,
      ),
      PillNavItem(
        icon: Icons.shopping_bag_outlined,
        label: 'Compras',
        color: colors.lime,
        motif: TileMotif.ponto,
      ),
      // `paper`, não `ink`: a PillNavBar em si já é `ink` (§9.8) — um item
      // `ink` selecionado ficaria invisível contra o próprio fundo da barra.
      // `paper` inverte (pill claro no fundo escuro) e ainda fecha o
      // quarteto de cores do §9.2.
      PillNavItem(
        icon: Icons.person_outline,
        label: 'Conta',
        color: colors.onInk,
        motif: TileMotif.diagonal,
      ),
    ];

    final selecting = ref.watch(recipeSelectionProvider) != null;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          _buildPages(),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: IgnorePointer(
                ignoring: selecting,
                child: AnimatedOpacity(
                  opacity: selecting ? 0 : 1,
                  duration: const Duration(milliseconds: 180),
                  child: KeyedSubtree(
                    key: ref
                        .read(tutorialTargetsProvider)[TutorialTarget.navBar],
                    child: PillNavBar(
                      items: items,
                      currentIndex: _tab,
                      onSelected: _select,
                      motion: _motion,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screen),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOutBack,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.6),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: selecting
                      ? const SelectionBar(key: ValueKey('selection-bar'))
                      : const SizedBox(key: ValueKey('no-selection')),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: SafeArea(
              child: Padding(
                // Clareia a `PillNavBar` (78 de altura visível) + folga.
                padding: const EdgeInsets.only(bottom: 96, right: 16),
                child: const RecipeDeleteDropTarget(),
              ),
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(bottom: 96),
                child: SyncStatusChip(),
              ),
            ),
          ),
          if (ref.watch(tutorialStepProvider) != null)
            const Positioned.fill(child: TutorialOverlay()),
          const AchievementWatcher(),
        ],
      ),
    );
  }
}

/// Uma aba na faixa deslizante: deslocada [offset] larguras da posição
/// central. Fora da tela (|offset| ≥ 1) some do layout e para os tickers, mas
/// continua montada — o estado da aba (rolagem, busca, filtros) se preserva.
class _TabSlot extends StatelessWidget {
  const _TabSlot({
    required this.offset,
    required this.heroes,
    required this.child,
  });

  final double offset;
  final bool heroes;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final visible = offset.abs() < 1;
    return Offstage(
      offstage: !visible,
      child: TickerMode(
        enabled: visible,
        child: RepaintBoundary(
          child: FractionalTranslation(
            translation: Offset(offset, 0),
            child: HeroMode(enabled: heroes, child: child),
          ),
        ),
      ),
    );
  }
}
