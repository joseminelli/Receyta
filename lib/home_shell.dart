import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'package:receyta/features/folders/recipe_drag.dart';
import 'package:receyta/features/recipes/receyta_import_flow.dart';
import 'package:receyta/features/recipes/recipes_page.dart';
import 'package:receyta/features/settings/account_page.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/pill_nav_bar.dart';
import 'package:receyta/widgets/state_badge.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Casca do app: as quatro seções (§9.2) sob a `PillNavBar` flutuante
/// (§9.8). Semana e Compras são placeholder até os blocos F e E.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _tab = 0;
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
    _mediaSub = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(_handleSharedMedia, onError: (_) {});
  }

  Future<void> _checkInitialShare() async {
    try {
      final media = await ReceiveSharingIntent.instance.getInitialMedia();
      debugPrint('[receyta] getInitialMedia -> ${media.length} arquivo(s): '
          '${media.map((m) => '${m.path} (${m.mimeType})').toList()}');
      await ReceiveSharingIntent.instance.reset();
      if (!mounted) return;
      _handleSharedMedia(media);
    } catch (e, st) {
      debugPrint('[receyta] getInitialMedia falhou: $e\n$st');
    }
  }

  void _handleSharedMedia(List<SharedMediaFile> media) {
    for (final file in media) {
      if (file.path.toLowerCase().endsWith('.receyta')) {
        importSharedReceytaFileFlow(ref, file.path);
        return;
      }
    }
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
        label: 'Semana',
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
            children: [
              const RecipesPage(),
              _ComingSoon(
                'Semana',
                icon: Icons.calendar_today_rounded,
                color: colors.violet,
              ),
              _ComingSoon(
                'Compras',
                icon: Icons.shopping_bag_outlined,
                color: colors.lime,
              ),
              const AccountPage(),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: PillNavBar(
                items: items,
                currentIndex: _tab,
                onSelected: (i) => setState(() => _tab = i),
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
        ],
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon(this.section, {required this.icon, required this.color});

  final String section;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground =
        color.computeLuminance() > 0.5 ? colors.ink : colors.onSaturated;
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StateBadge(icon: icon, background: color, foreground: foreground),
            const SizedBox(height: AppSpacing.lg),
            Text(section, style: context.texts.displaySmall),
            const SizedBox(height: AppSpacing.xs),
            Text('Em breve', style: context.texts.bodyMedium),
          ],
        ),
      ),
    );
  }
}
