import 'package:flutter/material.dart';

import 'package:receyta/splash.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/hero_number.dart';
import 'package:receyta/widgets/metric_stat.dart';
import 'package:receyta/widgets/pill_button.dart';
import 'package:receyta/widgets/pill_nav_bar.dart';
import 'package:receyta/widgets/section_header.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Galeria de componentes — entrypoint próprio, fora do app (§9.9).
///
/// ```
/// flutter run -t lib/gallery_app.dart
/// ```
///
/// Fica na raiz de `lib/` de propósito: é um entrypoint alternativo, não código
/// embarcado no app de produção, e revisar um componente não exige navegar até
/// a tela que o usa.
///
/// A galeria é **navegável**: um índice lista cada componente, e cada entrada
/// abre uma página só dele com todas as variantes e os fundos em que ele é
/// válido. É a folha de contato dos `lib/widgets/`.
void main() => runApp(const GalleryApp());

class GalleryApp extends StatefulWidget {
  const GalleryApp({super.key});

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  var _mode = ThemeMode.light;

  void _toggleTheme() => setState(() {
        _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
      });

  /// Liga o overlay de performance com
  /// `--dart-define=PERF_OVERLAY=true` — usado no benchmark do A4.
  static const _perfOverlay = bool.fromEnvironment('PERF_OVERLAY');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Receyta — Galeria',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _mode,
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: _perfOverlay,
      home: GalleryIndexPage(onToggleTheme: _toggleTheme),
    );
  }
}

/// Uma entrada do índice: título, uma linha de contexto e o corpo da página.
class GalleryEntry {
  const GalleryEntry({
    required this.title,
    required this.blurb,
    required this.builder,
    this.expand = false,
  });

  final String title;
  final String blurb;
  final WidgetBuilder builder;

  /// Quando `true`, o corpo ocupa a tela inteira (sem o scroll da casca) —
  /// para páginas que já são um scrollable, como o benchmark.
  final bool expand;
}

/// Registro único de tudo que a galeria mostra. Adicionar um componente é
/// adicionar uma linha aqui.
final List<GalleryEntry> galleryEntries = [
  GalleryEntry(
    title: 'Tipografia',
    blurb: 'A escala da §9.3 — Bricolage 800 contra a sans do sistema.',
    builder: (_) => const _TypographyPage(),
  ),
  GalleryEntry(
    title: 'SectionHeader',
    blurb: 'Eyebrow caps, título Display S, ação opcional à direita.',
    builder: (_) => const _SectionHeaderPage(),
  ),
  GalleryEntry(
    title: 'PillButton',
    blurb: 'Quatro variantes. Accent só existe sobre fundo escuro.',
    builder: (_) => const _PillButtonPage(),
  ),
  GalleryEntry(
    title: 'PillNavBar',
    blurb: 'Barra flutuante `ink`, item ativo abre para ícone + label.',
    builder: (_) => const _PillNavBarPage(),
  ),
  GalleryEntry(
    title: 'MetricStat',
    blurb: 'Valor + unidade sobre label caps. Preparo, cozimento, porções.',
    builder: (_) => const _MetricStatPage(),
  ),
  GalleryEntry(
    title: 'HeroNumber',
    blurb: 'Número ilustrativo sangrando na borda do bloco (§9.1).',
    builder: (_) => const _HeroNumberPage(),
  ),
  GalleryEntry(
    title: 'TilePattern',
    blurb: 'Os quatro módulos do azulejo, tom sobre tom (§9.4).',
    builder: (_) => const _TilePatternPage(),
  ),
  GalleryEntry(
    title: 'TilePattern — benchmark',
    blurb: '60 cards com padrão. Rode em --profile e confira 60fps no scroll.',
    builder: (_) => const _BenchmarkPage(),
    expand: true,
  ),
  GalleryEntry(
    title: 'Splash',
    blurb: 'Abertura animada sobre coral (§9.7). Toque para repetir.',
    builder: (_) => const _SplashPage(),
    expand: true,
  ),
];

class GalleryIndexPage extends StatelessWidget {
  const GalleryIndexPage({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
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
                onPressed: onToggleTheme,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            for (final entry in galleryEntries)
              _IndexTile(
                entry: entry,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _EntryScaffold(entry: entry),
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

class _IndexTile extends StatelessWidget {
  const _IndexTile({required this.entry, required this.onTap});

  final GalleryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: colors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.title, style: context.texts.displaySmall),
                      const SizedBox(height: AppSpacing.xs / 2),
                      Text(entry.blurb, style: context.texts.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.chevron_right, color: colors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Casca comum de cada página de componente: AppBar com o nome e o corpo
/// rolável com margem de tela.
class _EntryScaffold extends StatelessWidget {
  const _EntryScaffold({required this.entry});

  final GalleryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(entry.title)),
      body: SafeArea(
        child: entry.expand
            ? entry.builder(context)
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.screen),
                children: [
                  Text(entry.blurb, style: context.texts.bodyMedium),
                  const SizedBox(height: AppSpacing.xl),
                  entry.builder(context),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Páginas de componente
// ---------------------------------------------------------------------------

class _TypographyPage extends StatelessWidget {
  const _TypographyPage();

  @override
  Widget build(BuildContext context) {
    // Serve de prova visual da Bricolage: o tracking negativo e a entrelinha
    // de 0.92 aparecem no salto entre 48 e 10.
    return _Demo(
      label: 'Escala',
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
    );
  }
}

class _SectionHeaderPage extends StatelessWidget {
  const _SectionHeaderPage();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _Demo(
          label: 'Com eyebrow',
          child: SectionHeader(
            eyebrow: 'Esta semana',
            title: 'Estrogonofe de frango com arroz sete grãos',
          ),
        ),
        _Demo(
          label: 'Sem eyebrow, com ação',
          child: SectionHeader(
            title: 'Receitas',
            action: PillButton(
              label: 'Nova',
              icon: Icons.add,
              dense: true,
              onPressed: () {},
            ),
          ),
        ),
      ],
    );
  }
}

class _PillButtonPage extends StatelessWidget {
  const _PillButtonPage();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        _Demo(
          label: 'Sobre paper',
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
              PillButton(label: 'Com ícone', icon: Icons.add, onPressed: () {}),
              const PillButton(label: 'Desabilitado'),
            ],
          ),
        ),
        // Accent é lime sobre ink: a variante que só funciona em fundo escuro.
        // Sobre paper ela sumiria (§9.2).
        _Demo(
          label: 'Accent — só sobre ink',
          background: colors.ink,
          child: Row(
            children: [
              PillButton(
                label: 'Accent',
                variant: PillButtonVariant.accent,
                onPressed: () {},
              ),
              const SizedBox(width: AppSpacing.xs),
              PillButton(
                label: 'Ícone',
                icon: Icons.check,
                variant: PillButtonVariant.accent,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PillNavBarPage extends StatefulWidget {
  const _PillNavBarPage();

  @override
  State<_PillNavBarPage> createState() => _PillNavBarPageState();
}

class _PillNavBarPageState extends State<_PillNavBarPage> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      label: 'Três seções',
      background: context.colors.paperSoft,
      padded: false,
      child: PillNavBar(
        currentIndex: _navIndex,
        onSelected: (i) => setState(() => _navIndex = i),
        items: [
          PillNavItem(
              icon: Icons.restaurant_menu,
              label: 'Receitas',
              color: context.colors.coral,
              motif: TileMotif.arco),
          PillNavItem(
              icon: Icons.calendar_month,
              label: 'Semana',
              color: context.colors.violet,
              motif: TileMotif.meiaLua),
          PillNavItem(
              icon: Icons.shopping_basket,
              label: 'Compras',
              color: context.colors.lime,
              motif: TileMotif.ponto),
        ],
      ),
    );
  }
}

class _MetricStatPage extends StatelessWidget {
  const _MetricStatPage();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        const _Demo(
          label: 'Sobre paper',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MetricStat(value: '15', unit: 'min', label: 'Preparo'),
              MetricStat(value: '25', unit: 'min', label: 'Cozimento'),
              MetricStat(value: '4', label: 'Porções'),
            ],
          ),
        ),
        // Sobre coral, o label usa a versão clara do próprio matiz — cinza
        // nesse fundo fica sujo (§9.2).
        _Demo(
          label: 'Sobre coral',
          background: colors.coral,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MetricStat(
                value: '15',
                unit: 'min',
                label: 'Preparo',
                color: colors.onSaturated,
                labelColor: colors.coralMuted,
              ),
              MetricStat(
                value: '4',
                label: 'Porções',
                color: colors.onSaturated,
                labelColor: colors.coralMuted,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroNumberPage extends StatelessWidget {
  const _HeroNumberPage();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return _Demo(
      label: 'Ancorado em cantos opostos',
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
    );
  }
}

class _TilePatternPage extends StatelessWidget {
  const _TilePatternPage();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Cada módulo na cor da sua "uso típico" (§9.4). Na prática o módulo vem do
    // id da receita e a cor vem da seção — os dois são independentes.
    final specs = <(String, TileMotif, Color, Color, Color?)>[
      ('arco', TileMotif.arco, colors.coral, colors.coralPattern, null),
      ('meiaLua', TileMotif.meiaLua, colors.violet, colors.violetPattern, null),
      (
        'diagonal',
        TileMotif.diagonal,
        colors.ink,
        colors.inkPattern,
        colors.inkPatternAlt
      ),
      ('ponto', TileMotif.ponto, colors.lime, colors.limePattern, null),
    ];

    return Column(
      children: [
        for (final (name, motif, bg, pattern, alt) in specs)
          _Demo(
            label: name,
            padded: false,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: SizedBox(
                height: 120,
                child: TilePattern(
                  motif: motif,
                  background: bg,
                  patternColor: pattern,
                  patternColorAlt: alt,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BenchmarkPage extends StatelessWidget {
  const _BenchmarkPage();

  static const _names = [
    'Frango ao curry',
    'Estrogonofe',
    'Bolo de fubá',
    'Lasanha à bolonhesa',
    'Sopa de legumes',
    'Pão de queijo',
    'Risoto de cogumelos',
    'Feijoada',
    'Panqueca de banana',
    'Salada caesar',
    'Torta de limão',
    'Moqueca',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.screen),
      // 60 cards: a régua do "pronto quando" do A4.
      itemCount: 60,
      itemBuilder: (context, i) {
        final id = 'recipe-$i';
        final name = _names[i % _names.length];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: SizedBox(
              height: 128,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  TilePattern(
                    motif: tileMotifForId(id),
                    background: colors.coral,
                    patternColor: colors.coralPattern,
                  ),
                  HeroNumber(
                    value: '${8 + i % 40}',
                    color: colors.onSaturated,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      name,
                      style: context.texts.displaySmall?.copyWith(
                        color: colors.onSaturated,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SplashPage extends StatefulWidget {
  const _SplashPage();

  @override
  State<_SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<_SplashPage> {
  int _run = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _run++),
      child: Splash(
        // `ready` simula a inicialização do Drift (A7); ~900ms.
        key: ValueKey(_run),
        ready: Future<void>.delayed(const Duration(milliseconds: 900)),
        onComplete: () {},
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Auxiliares de apresentação
// ---------------------------------------------------------------------------

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
                    color: context.colors.onSaturated,
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
