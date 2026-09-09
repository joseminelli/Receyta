import 'package:flutter/material.dart';

import 'package:receyta/features/recipes/recipes_page.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/pill_nav_bar.dart';

/// Casca do app: as três seções (§9.2) sob a `PillNavBar` flutuante (§9.8).
/// Semana e Compras são placeholder até os blocos F e E.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  static const _items = [
    PillNavItem(icon: Icons.menu_book_rounded, label: 'Receitas'),
    PillNavItem(icon: Icons.calendar_today_rounded, label: 'Semana'),
    PillNavItem(icon: Icons.shopping_bag_outlined, label: 'Compras'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _tab,
            children: const [
              RecipesPage(),
              _ComingSoon('Semana'),
              _ComingSoon('Compras'),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: PillNavBar(
                items: _items,
                currentIndex: _tab,
                onSelected: (i) => setState(() => _tab = i),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon(this.section);

  final String section;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 40,
              color: context.colors.textMuted,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(section, style: context.texts.displaySmall),
            Text('Em breve', style: context.texts.bodyMedium),
          ],
        ),
      ),
    );
  }
}
