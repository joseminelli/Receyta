import 'package:flutter/material.dart';

import 'package:receyta/features/folders/recipe_drag.dart';
import 'package:receyta/features/recipes/recipes_page.dart';
import 'package:receyta/features/settings/account_page.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/pill_nav_bar.dart';
import 'package:receyta/widgets/state_badge.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Casca do app: as três seções (§9.2) sob a `PillNavBar` flutuante (§9.8).
/// Semana e Compras são placeholder até os blocos F e E.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

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
