import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/core/tile_style.dart';
import 'package:receyta/features/mascot/controllers/mascot_mood_provider.dart';
import 'package:receyta/features/mascot/widgets/animated_mascot.dart';
import 'package:receyta/features/onboarding/controllers/onboarding_seen.dart';
import 'package:receyta/features/onboarding/controllers/tutorial.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/pill_button.dart';
import 'package:receyta/widgets/tile_appearance.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Introdução de primeiro uso, cinco telas no desenho do app — bloco com a cor
/// e a textura da seção em cima e o texto numa folha clara embaixo:
/// abertura com a marca e os mascotes, três recursos (receitas, semana,
/// compras) com um exemplo animado e, no fim, "por onde começar?", que leva
/// direto ao tour, ao formulário de receita ou à home. Aparece uma vez só.
class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage> {
  final _controller = PageController();
  int _page = 0;

  static const _final = 4;
  static const _mascotScope = 'welcome';

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) ref.read(mascotMoodProvider(_mascotScope).notifier).wave();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _enter({bool tour = false}) async {
    await markOnboardingSeen();
    if (tour) await markTutorialPending();
    if (!mounted) return;
    context.go('/');
  }

  void _next() {
    if (_page >= _final) return;
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pages = <_PageData>[
      _PageData(
        color: TileColor.ink,
        motif: TileMotif.arco,
        title: 'Receitas do seu jeito',
        body: 'Guarde, planeje a semana e cozinhe sem sair do app. '
            'Tudo fica no seu aparelho.',
        kind: _PageKind.intro,
      ),
      _PageData(
        color: TileColor.coral,
        motif: TileMotif.arco,
        eyebrow: '01  ·  RECEITAS',
        title: 'Suas receitas, num lugar só',
        body: 'Digite, importe de um link, de uma foto ou de um arquivo. '
            'Tudo fica guardado no seu aparelho.',
        mock: (active) => _RecipeMock(active: active),
        mascot: MascotKind.cloche,
      ),
      _PageData(
        color: TileColor.violet,
        motif: TileMotif.meiaLua,
        eyebrow: '02  ·  AGENDA',
        title: 'Planeje a semana',
        body: 'Escolha o que cozinhar em cada dia e veja o mês de relance. '
            'Sem decidir tudo na hora da fome.',
        mock: (active) => _WeekMock(active: active),
      ),
      _PageData(
        color: TileColor.ink,
        motif: TileMotif.ponto,
        eyebrow: '03  ·  COMPRAS',
        title: 'Compras sem conta de cabeça',
        body: 'A lista sai das receitas, com as quantidades já somadas. No '
            'modo cozinha, os timers ficam à vista até com o app minimizado.',
        mock: (active) => _ShoppingMock(active: active),
        mascot: MascotKind.pote,
      ),
      _PageData(
        color: TileColor.ink,
        motif: TileMotif.arco,
        title: 'Tudo pronto!',
        body: '',
        kind: _PageKind.finale,
      ),
    ];
    final tiles = [
      for (final p in pages)
        resolveTileAppearance(colors, color: p.color, motif: p.motif),
    ];

    return Scaffold(
      backgroundColor: colors.paper,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) {
                    setState(() => _page = i);
                    ref
                        .read(mascotMoodProvider(_mascotScope).notifier)
                        .celebrate();
                  },
                  children: [
                    for (var i = 0; i < pages.length; i++)
                      _WelcomeScreen(
                        data: pages[i],
                        tile: tiles[i],
                        index: i,
                        controller: _controller,
                        active: i == _page,
                        onTour: () => _enter(tour: true),
                        onEnter: () => _enter(),
                      ),
                  ],
                ),
              ),
              _buildBottomBar(context),
            ],
          ),
          if (_page != _final)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.xs,
                    right: AppSpacing.sm,
                  ),
                  child: TextButton(
                    onPressed: () => _enter(tour: true),
                    style: TextButton.styleFrom(
                      foregroundColor: tiles[_page].onColor,
                      minimumSize: const Size(
                        AppSpacing.minTapTarget,
                        AppSpacing.minTapTarget,
                      ),
                    ),
                    child: const Text('Pular'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final colors = context.colors;
    if (_page == _final) {
      return const SafeArea(top: false, child: SizedBox(height: AppSpacing.md));
    }
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.lg,
        ),
        child: _page == 0
            ? SizedBox(
                width: double.infinity,
                child: PillButton(
                  label: 'Vamos lá',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: _next,
                ),
              )
            : Row(
                children: [
                  for (var i = 1; i < _final; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.only(right: 6),
                      width: i == _page ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? colors.onPaper : colors.paperSoft,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  const Spacer(),
                  PillButton(
                    label: 'Próximo',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _next,
                  ),
                ],
              ),
      ),
    );
  }
}

enum _PageKind { intro, feature, finale }

class _PageData {
  const _PageData({
    required this.color,
    required this.motif,
    required this.title,
    required this.body,
    this.kind = _PageKind.feature,
    this.eyebrow,
    this.mock,
    this.mascot,
  });

  final TileColor color;
  final TileMotif motif;
  final String title;
  final String body;
  final _PageKind kind;

  /// Rótulo pequeno no canto do bloco ("01 · RECEITAS").
  final String? eyebrow;
  final Widget Function(bool active)? mock;
  final MascotKind? mascot;
}

class _WelcomeScreen extends StatelessWidget {
  const _WelcomeScreen({
    required this.data,
    required this.tile,
    required this.index,
    required this.controller,
    required this.active,
    required this.onTour,
    required this.onEnter,
  });

  final _PageData data;
  final TileAppearance tile;
  final int index;
  final PageController controller;
  final bool active;
  final VoidCallback onTour;
  final VoidCallback onEnter;

  /// Espaço livre embaixo do exemplo pro mascote ficar ao lado dele, e não
  /// por cima.
  static const _mascotReserve = 112.0;

  @override
  Widget build(BuildContext context) {
    final finale = data.kind == _PageKind.finale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 11, child: _buildBlock(context)),
        Expanded(
          flex: 8,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              0,
            ),
            child: finale
                ? SingleChildScrollView(child: _buildFinale(context))
                : _buildText(context),
          ),
        ),
      ],
    );
  }

  Widget _buildBlock(BuildContext context) {
    final intro = data.kind == _PageKind.intro;
    final finale = data.kind == _PageKind.finale;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadii.lg + 10),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          TilePattern(
            motif: tile.motif,
            background: tile.background,
            patternColor: intro || finale
                ? context.colors.onInk.withValues(alpha: 0.09)
                : tile.patternColor,
            patternColorAlt: intro || finale
                ? context.colors.onInk.withValues(alpha: 0.05)
                : tile.patternColorAlt,
            tile: 72,
          ),
          if (intro) _buildIntroCenter(context),
          if (finale) _buildFinaleCenter(context),
          if (data.mock != null) _buildMock(context),
          if (data.eyebrow != null) _buildEyebrow(context),
          if (intro) ...[
            _SlideMascot(
              kind: MascotKind.cloche,
              index: index,
              controller: controller,
              width: 150,
            ),
            _SlideMascot(
              kind: MascotKind.pote,
              index: index,
              controller: controller,
              width: 112,
            ),
          ] else if (finale) ...[
            _SlideMascot(
              kind: MascotKind.cloche,
              index: index,
              controller: controller,
              width: 120,
            ),
            _SlideMascot(
              kind: MascotKind.pote,
              index: index,
              controller: controller,
              width: 90,
            ),
          ] else if (data.mascot != null)
            _SlideMascot(
              kind: data.mascot!,
              index: index,
              controller: controller,
              width: data.mascot == MascotKind.pote ? 104 : 132,
            ),
        ],
      ),
    );
  }

  Widget _buildEyebrow(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          0,
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(
            data.eyebrow!,
            style: context.texts.labelLarge?.copyWith(
              color: tile.onColor,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCenter(BuildContext context) {
    final colors = context.colors;
    final style = AppTextStyles.display(76).copyWith(
      color: colors.onInk,
      height: 1,
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xxl,
          AppSpacing.xl,
          _mascotReserve,
        ),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutBack,
            builder: (context, t, child) => Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text.rich(
                    TextSpan(
                      style: style,
                      children: [
                        const TextSpan(text: 'Rece'),
                        TextSpan(
                          text: 'y',
                          style: style.copyWith(color: colors.coral),
                        ),
                        const TextSpan(text: 'tas'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'O caderno de receitas que cabe no bolso',
                  textAlign: TextAlign.center,
                  style: context.texts.bodyLarge?.copyWith(
                    color: colors.onInk.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinaleCenter(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xxl,
          AppSpacing.xl,
          _mascotReserve,
        ),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: active ? 1 : 0),
            duration: Duration(milliseconds: active ? 700 : 0),
            curve: Curves.easeOutBack,
            builder: (context, t, child) => Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.lime,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_rounded, size: 36, color: colors.ink),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.display(52).copyWith(
                    color: colors.onInk,
                    height: 1,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Seu caderno de receitas está aberto.',
                  textAlign: TextAlign.center,
                  style: context.texts.bodyLarge?.copyWith(
                    color: colors.onInk.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMock(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xxl + AppSpacing.md,
        AppSpacing.xl,
        data.mascot != null ? _mascotReserve : AppSpacing.lg,
      ),
      child: LayoutBuilder(
        builder: (context, box) => Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: box.maxWidth,
              child: Transform.rotate(
                angle: -0.03,
                child: Material(
                  color: colors.paperSoft,
                  elevation: 8,
                  shadowColor: Colors.black54,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: data.mock!(active),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(data.title, style: AppTextStyles.display(36)),
        const SizedBox(height: AppSpacing.sm),
        Text(data.body, style: context.texts.bodyLarge),
      ],
    );
  }

  Widget _buildFinale(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Vamos conhecer o app?', style: AppTextStyles.display(30)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Um tour de cerca de 1 minuto mostra onde fica cada coisa. '
          'Preparamos uma receita de exemplo para você explorar.',
          style: context.texts.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        PillButton(
          label: 'Começar o tour',
          icon: Icons.explore_outlined,
          onPressed: onTour,
        ),
        const SizedBox(height: AppSpacing.xs),
        Center(
          child: TextButton(
            onPressed: onEnter,
            style: TextButton.styleFrom(
              foregroundColor: colors.textMuted,
              minimumSize: const Size(0, AppSpacing.minTapTarget),
            ),
            child: const Text('Agora não, entrar no app'),
          ),
        ),
        Center(
          child: Text(
            'Você pode rever o tour em Configurações.',
            style: context.texts.labelSmall?.copyWith(color: colors.textMuted),
          ),
        ),
      ],
    );
  }
}

/// Mascote da tela: entra quicando de baixo e, ao deslizar, anda mais rápido
/// que o cartão e se inclina para o lado do movimento (parallax). O Pote fica
/// à direita e o Cloche à esquerda.
class _SlideMascot extends StatelessWidget {
  const _SlideMascot({
    required this.kind,
    required this.index,
    required this.controller,
    required this.width,
  });

  final MascotKind kind;
  final int index;
  final PageController controller;
  final double width;

  double _page() {
    if (controller.hasClients && controller.position.haveDimensions) {
      return controller.page ?? controller.initialPage.toDouble();
    }
    return controller.initialPage.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final onRight = kind == MascotKind.pote;
    return Positioned(
      left: onRight ? null : AppSpacing.md,
      right: onRight ? AppSpacing.md : null,
      bottom: 6,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.elasticOut,
        builder: (context, enter, child) => AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final delta = index - _page();
            return Transform.translate(
              offset: Offset(delta * 140, (1 - enter) * 120),
              child: Transform.rotate(
                angle: delta * 0.4,
                alignment: Alignment.bottomCenter,
                child: child,
              ),
            );
          },
        ),
        child: AnimatedMascot(kind: kind, scope: 'welcome', width: width),
      ),
    );
  }
}

/// Mostra o conteúdo com `shown` falso e vira verdadeiro `delay` depois de
/// [active] ficar verdadeiro; ao sair da tela volta a falso, então a animação
/// toca de novo quando a pessoa volta.
class _Reveal extends StatefulWidget {
  const _Reveal({
    required this.active,
    required this.builder,
    this.delay = Duration.zero,
  });

  final bool active;
  final Duration delay;
  final Widget Function(BuildContext context, bool shown) builder;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> {
  bool _shown = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.active) _schedule();
  }

  @override
  void didUpdateWidget(_Reveal old) {
    super.didUpdateWidget(old);
    if (widget.active == old.active) return;
    if (widget.active) {
      _schedule();
    } else {
      _timer?.cancel();
      _shown = false;
    }
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(widget.delay + const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _shown);
}

/// Entra deslizando de baixo e aparecendo.
class _Rise extends StatelessWidget {
  const _Rise({
    required this.active,
    required this.index,
    required this.child,
  });

  final bool active;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _Reveal(
      active: active,
      delay: Duration(milliseconds: 140 * index),
      builder: (_, shown) => AnimatedSlide(
        offset: shown ? Offset.zero : const Offset(0, 0.4),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: shown ? 1 : 0,
          duration: const Duration(milliseconds: 320),
          child: child,
        ),
      ),
    );
  }
}

/// Número que sobe de zero até [to] quando a tela fica ativa.
class _CountUp extends StatelessWidget {
  const _CountUp({
    required this.active,
    required this.to,
    required this.style,
  });

  final bool active;
  final int to;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: active ? to.toDouble() : 0),
      duration: Duration(milliseconds: active ? 1100 : 0),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text('${v.round()}', style: style),
    );
  }
}

/// Exemplo de card de receita, com as quatro formas de adicionar uma.
class _RecipeMock extends StatelessWidget {
  const _RecipeMock({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget method(IconData icon, String label) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.ink,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 19, color: colors.lime),
            ),
            const SizedBox(height: 4),
            Text(label, style: context.texts.labelSmall),
          ],
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Rise(
          active: active,
          index: 0,
          child: Text(
            'FRANGO AO CURRY',
            style: context.texts.labelSmall?.copyWith(color: colors.textMuted),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        _Rise(
          active: active,
          index: 1,
          child: Text('Frango ao curry', style: AppTextStyles.display(30)),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _CountUp(active: active, to: 15, style: AppTextStyles.display(34)),
            Text(' m preparo', style: context.texts.bodyMedium),
            const SizedBox(width: AppSpacing.md),
            _CountUp(active: active, to: 25, style: AppTextStyles.display(34)),
            Text(' m fogão', style: context.texts.bodyMedium),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Divider(height: 1, color: colors.paper),
        const SizedBox(height: AppSpacing.sm),
        _Rise(
          active: active,
          index: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              method(Icons.link, 'Link'),
              method(Icons.photo_camera_outlined, 'Foto'),
              method(Icons.description_outlined, 'Arquivo'),
              method(Icons.edit_outlined, 'Digitar'),
            ],
          ),
        ),
      ],
    );
  }
}

/// Exemplo da semana: dia + prato, entrando um por vez.
class _WeekMock extends StatelessWidget {
  const _WeekMock({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget row(int i, String day, String dish) => _Rise(
          active: active,
          index: i,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    day,
                    style: context.texts.labelSmall
                        ?.copyWith(color: colors.textMuted),
                  ),
                ),
                Expanded(
                  child: Text(dish, style: AppTextStyles.display(20)),
                ),
              ],
            ),
          ),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row(0, 'SEG', 'Homus com pão sírio'),
        Divider(height: 1, color: colors.paper),
        row(1, 'QUA', 'Frango ao curry'),
        Divider(height: 1, color: colors.paper),
        row(2, 'SEX', 'Sopa de abóbora'),
      ],
    );
  }
}

/// Exemplo de lista de compras: os itens vão sendo marcados em sequência.
class _ShoppingMock extends StatelessWidget {
  const _ShoppingMock({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget row(int i, String text) => _Rise(
          active: active,
          index: i,
          child: _Reveal(
            active: active,
            delay: Duration(milliseconds: 600 + 450 * i),
            builder: (_, done) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: done ? colors.onPaper : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.onPaper, width: 1.6),
                    ),
                    child: AnimatedScale(
                      scale: done ? 1 : 0,
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutBack,
                      child: Icon(Icons.check, size: 14, color: colors.lime),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    style: AppTextStyles.display(20).copyWith(
                      decoration: done ? TextDecoration.lineThrough : null,
                      color: done ? colors.textMuted : colors.onPaper,
                    ),
                    child: Text(text),
                  ),
                ],
              ),
            ),
          ),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row(0, '1,3 kg de farinha'),
        row(1, '3 ovos'),
        row(2, '400 g de tomate'),
      ],
    );
  }
}
