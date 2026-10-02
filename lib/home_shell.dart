import 'dart:async';

import 'package:flutter/material.dart';
import 'package:receyta/data/services/auto_backup_service.dart';
import 'package:receyta/data/services/home_widget_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'package:receyta/features/folders/screens/recipe_drag.dart';
import 'package:receyta/features/onboarding/controllers/tutorial.dart';
import 'package:receyta/features/onboarding/screens/tutorial_overlay.dart';
import 'package:receyta/features/recipes/screens/receyta_import_flow.dart';
import 'package:receyta/features/planner/screens/month_page.dart';
import 'package:receyta/features/recipes/screens/recipes_page.dart';
import 'package:receyta/features/settings/controllers/reminder_settings.dart';
import 'package:receyta/features/settings/screens/account_page.dart';
import 'package:receyta/features/shopping/screens/shopping_lists_page.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/widgets/pill_nav_bar.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Casca do app: as quatro seções (§9.2) sob a `PillNavBar` flutuante
/// (§9.8). Semana é placeholder até o bloco F; Compras já é real (E3).
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _tab = 0;

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
    _checkInitialShare();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        ref.read(tutorialControllerProvider).startIfNeeded();
        ref.read(reminderSettingsProvider.notifier).syncOnStart();
        ref.read(homeWidgetSyncProvider).start();
        ref.read(autoBackupProvider.notifier).runIfDue();
      },
    );
    _mediaSub = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(_handleSharedMedia, onError: (_) {});
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
    importSharedReceytaFileFlow(ref, media.first.path);
  }

  @override
  void dispose() {
    _mediaSub?.cancel();
    super.dispose();
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
        color: colors.paper,
        motif: TileMotif.diagonal,
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _tab,
            // `HeroMode`: o `IndexedStack` mantém as abas escondidas montadas,
            // e os `Hero` delas continuavam valendo — abrir uma receita pela
            // Semana fazia voar o card da aba Receitas, que nem estava na tela.
            children: [
              for (final (i, page) in const [
                RecipesPage(),
                MonthPage(),
                ShoppingListsPage(),
                AccountPage(),
              ].indexed)
                if (_visited.contains(i))
                  HeroMode(enabled: i == _tab, child: page)
                else
                  const SizedBox.shrink(),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: KeyedSubtree(
                key: ref.read(tutorialTargetsProvider)[TutorialTarget.navBar],
                child: PillNavBar(
                  items: items,
                  currentIndex: _tab,
                  onSelected: (i) => setState(() {
                    _tab = i;
                    _visited.add(i);
                  }),
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
          if (ref.watch(tutorialStepProvider) != null)
            const Positioned.fill(child: TutorialOverlay()),
        ],
      ),
    );
  }
}
