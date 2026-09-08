import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../app/theme/tokens.dart';
import '../shared/widgets/hero_number.dart';
import '../shared/widgets/metric_stat.dart';
import '../shared/widgets/pill_button.dart';
import '../shared/widgets/pill_nav_bar.dart';
import '../shared/widgets/section_header.dart';

/// Galeria de componentes — entrypoint próprio, fora do app (§9.9).
///
/// ```
/// flutter run -t lib/gallery/gallery_app.dart
/// ```
///
/// Mora fora de `features/` de propósito: nada aqui é embarcado no app de
/// produção, e revisar um componente não exige navegar até a tela que o usa.
void main() => runApp(const GalleryApp());

class GalleryApp extends StatefulWidget {
  const GalleryApp({super.key});

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  var _mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Receyta — Galeria',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _mode,
      debugShowCheckedModeBanner: false,
      home: GalleryPage(
        onToggleTheme: () => setState(() {
          _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
        }),
      ),
    );
  }
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            SectionHeader(
              eyebrow: 'Receyta',
              title: 'Galeria',
              action: PillButton(
                label: 'Tema',
                icon: Icons.contrast,
                variant: PillButtonVariant.secondary,
                dense: true,
                onPressed: widget.onToggleTheme,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Serve de prova visual da Bricolage: o tracking negativo e a
            // entrelinha de 0.92 aparecem no salto entre 48 e 10.
            _Demo(
              label: 'Tipografia',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Display L 48', style: context.texts.displayLarge),
                  Text('Display M 25', style: context.texts.displayMedium),
                  Text('Display S 22', style: context.texts.displaySmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Corpo 14 — sans do sistema, peso 400.',
                      style: context.texts.bodyMedium),
                  Text('Label 12', style: context.texts.labelLarge),
                  Text('LABEL CAPS 10', style: context.texts.labelSmall),
                ],
              ),
            ),

            _Demo(
              label: 'SectionHeader',
              child: const SectionHeader(
                eyebrow: 'Esta semana',
                title: 'Estrogonofe de frango com arroz sete grãos',
              ),
            ),

            _Demo(
              label: 'PillButton',
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  PillButton(label: 'Primary', onPressed: () {}),
                  PillButton(
                    label: 'Secondary',
                    variant: PillButtonVariant.secondary,
                    onPressed: () {},
                  ),
                  PillButton(
                    label: 'Ghost',
                    variant: PillButtonVariant.ghost,
                    onPressed: () {},
                  ),
                  PillButton(
                    label: 'Com ícone',
                    icon: Icons.add,
                    onPressed: () {},
                  ),
                  const PillButton(label: 'Desabilitado'),
                ],
              ),
            ),

            // Accent é lime sobre ink: a variante que só funciona em fundo
            // escuro. Sobre paper ela sumiria (§9.2).
            _Demo(
              label: 'PillButton — accent sobre ink',
              background: colors.ink,
              child: Row(
                children: [
                  PillButton(
                    label: 'Accent',
                    variant: PillButtonVariant.accent,
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            _Demo(
              label: 'PillNavBar',
              background: colors.paperSoft,
              padded: false,
              child: PillNavBar(
                currentIndex: _navIndex,
                onSelected: (i) => setState(() => _navIndex = i),
                items: const [
                  PillNavItem(icon: Icons.restaurant_menu, label: 'Receitas'),
                  PillNavItem(icon: Icons.calendar_month, label: 'Semana'),
                  PillNavItem(icon: Icons.shopping_basket, label: 'Compras'),
                ],
              ),
            ),

            _Demo(
              label: 'MetricStat',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  MetricStat(value: '15', unit: 'min', label: 'Preparo'),
                  MetricStat(value: '25', unit: 'min', label: 'Cozimento'),
                  MetricStat(value: '4', label: 'Porções'),
                ],
              ),
            ),

            // Sobre coral, o label usa a versão clara do próprio matiz —
            // cinza nesse fundo fica sujo (§9.2).
            _Demo(
              label: 'MetricStat sobre coral',
              background: colors.coral,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MetricStat(
                    value: '15',
                    unit: 'min',
                    label: 'Preparo',
                    color: Colors.white,
                    labelColor: colors.coralLight,
                  ),
                  MetricStat(
                    value: '4',
                    label: 'Porções',
                    color: Colors.white,
                    labelColor: colors.coralLight,
                  ),
                ],
              ),
            ),

            _Demo(
              label: 'HeroNumber',
              padded: false,
              child: SizedBox(
                height: 160,
                child: Row(
                  children: [
                    Expanded(
                      child: _HeroCard(
                        background: colors.coral,
                        numberColor: colors.coralLight,
                        value: '25',
                        caption: 'Frango ao curry',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _HeroCard(
                        background: colors.violet,
                        numberColor: colors.violetPattern,
                        value: '4',
                        caption: 'Porções',
                        corner: Alignment.topRight,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

/// Bloco de demonstração: label caps + o componente sobre o fundo escolhido.
class _Demo extends StatelessWidget {
  const _Demo({
    required this.label,
    required this.child,
    this.background,
    this.padded = true,
  });

  final String label;
  final Widget child;
  final Color? background;

  /// Desligue quando o próprio componente já traz margem (a nav bar traz).
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: context.texts.labelSmall),
          const SizedBox(height: AppSpacing.sm),
          DecoratedBox(
            decoration: BoxDecoration(
              color: background ?? colors.paperSoft,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Padding(
              padding: EdgeInsets.all(padded ? AppSpacing.md : 0),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.background,
    required this.numberColor,
    required this.value,
    required this.caption,
    this.corner = Alignment.bottomRight,
  });

  final Color background;
  final Color numberColor;
  final String value;
  final String caption;
  final Alignment corner;

  @override
  Widget build(BuildContext context) {
    // O clip é o que torna o sangramento intencional em vez de vazamento.
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: ColoredBox(
        color: background,
        child: Stack(
          fit: StackFit.expand,
          children: [
            HeroNumber(value: value, color: numberColor, corner: corner),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  caption,
                  style: context.texts.displaySmall?.copyWith(
                    color: Colors.white,
                  ),
                  maxLines: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
