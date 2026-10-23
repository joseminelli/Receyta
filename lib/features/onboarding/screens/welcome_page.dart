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

/// Introdução de primeiro uso: três telas curtas (receitas, semana, compras)
/// no mesmo desenho do app — bloco com a cor e a textura da seção em cima e,
/// por cima dele, um cartão claro com um exemplo de verdade do recurso. Aparece
/// uma vez só; "Pular" e "Começar" levam à home.
class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage> {
  final _controller = PageController();
  int _page = 0;

  static const _last = 2;
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

  Future<void> _finish() async {
    await markOnboardingSeen();
    await markTutorialPending();
    if (mounted) context.go('/');
  }

  void _next() {
    if (_page >= _last) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final slides = [
      _SlideData(
        color: TileColor.coral,
        motif: TileMotif.arco,
        title: 'Suas receitas, num lugar só',
        body: 'Digite, importe de um link, de uma foto ou de um arquivo. '
            'Tudo fica guardado no seu aparelho.',
        mock: (active) => _RecipeMock(active: active),
        mascot: MascotKind.cloche,
      ),
      _SlideData(
        color: TileColor.violet,
        motif: TileMotif.meiaLua,
        title: 'Planeje a semana',
        body: 'Escolha o que cozinhar em cada dia e veja o mês de relance. '
            'Sem decidir tudo na hora da fome.',
        mock: (active) => _WeekMock(active: active),
      ),
      _SlideData(
        color: TileColor.ink,
        motif: TileMotif.ponto,
        title: 'Compras sem conta de cabeça',
        body: 'A lista sai das receitas, com as quantidades já somadas. No '
            'modo cozinha, os timers ficam à vista até com o app minimizado.',
        mock: (active) => _ShoppingMock(active: active),
        mascot: MascotKind.pote,
      ),
    ];

    return Scaffold(
      backgroundColor: colors.paper,
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (i) {
                setState(() => _page = i);
                ref.read(mascotMoodProvider(_mascotScope).notifier).celebrate();
              },
              children: [
                for (var i = 0; i < slides.length; i++)
                  _Slide(
                    data: slides[i],
                    index: i,
                    controller: _controller,
                    active: i == _page,
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < slides.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 6),
                          width: i == _page ? 26 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color:
                                i == _page ? colors.onPaper : colors.paperSoft,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  if (_page != _last)
                    TextButton(
                      onPressed: _finish,
                      child: const Text('Pular'),
                    ),
                  const SizedBox(width: AppSpacing.xs),
                  PillButton(
                    label: _page == _last ? 'Começar' : 'Próximo',
                    icon: _page == _last ? null : Icons.arrow_forward_rounded,
                    onPressed: _next,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideData {
  const _SlideData({
    required this.color,
    required this.motif,
    required this.title,
    required this.body,
    required this.mock,
    this.mascot,
  });

  final TileColor color;
  final TileMotif motif;
  final String title;
  final String body;
  final Widget Function(bool active) mock;
  final MascotKind? mascot;
}

class _Slide extends StatelessWidget {
  const _Slide({
    required this.data,
    required this.index,
    required this.controller,
    required this.active,
  });

  final _SlideData data;
  final int index;
  final PageController controller;

  /// Esta é a tela à vista: os exemplos animam quando ela fica ativa.
  final bool active;

  /// Espaço livre embaixo do exemplo pro mascote ficar ao lado dele, e não
  /// por cima.
  static const _mascotReserve = 112.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tile = resolveTileAppearance(
      colors,
      color: data.color,
      motif: data.motif,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 11,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(AppRadii.lg + 10),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                TilePattern(
                  motif: tile.motif,
                  background: tile.background,
                  patternColor: tile.patternColor,
                  patternColorAlt: tile.patternColorAlt,
                  tile: 72,
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xxl,
                    AppSpacing.xl,
                    data.mascot != null ? _mascotReserve : AppSpacing.lg,
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Material(
                        color: colors.paperSoft,
                        elevation: 6,
                        shadowColor: Colors.black54,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: data.mock(active),
                        ),
                      ),
                    ),
                  ),
                ),
                if (data.mascot != null)
                  _SlideMascot(
                    kind: data.mascot!,
                    index: index,
                    controller: controller,
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 8,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title, style: AppTextStyles.display(36)),
                const SizedBox(height: AppSpacing.sm),
                Text(data.body, style: context.texts.bodyLarge),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Mascote da tela: entra quicando de baixo e, ao deslizar, anda mais rápido
/// que o cartão e se inclina para o lado do movimento (parallax).
class _SlideMascot extends StatelessWidget {
  const _SlideMascot({
    required this.kind,
    required this.index,
    required this.controller,
  });

  final MascotKind kind;
  final int index;
  final PageController controller;

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
        child: AnimatedMascot(
          kind: kind,
          scope: 'welcome',
          width: onRight ? 104 : 132,
        ),
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
