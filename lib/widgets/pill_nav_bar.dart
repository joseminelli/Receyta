import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import 'package:receyta/core/tile_style.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';

/// Um destino da [PillNavBar]. `color` é a cor da seção (§9.2) — o `motif` fica
/// só de referência pra quem consome via [TileMotif], a navbar em si não
/// desenha o azulejo (ficava grosseiro nesse tamanho).
class PillNavItem {
  const PillNavItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.motif,
  });

  final IconData icon;
  final String label;
  final Color color;
  final TileMotif motif;
}

/// Ilha de navegação flutuante em pílula `ink` (§9.8) — compacta, centrada, não
/// uma barra de ponta a ponta. Inativos mostram só o ícone; o ativo ganha a
/// cor da seção e o ícone entra num medalhão, com ícone + label.
///
/// A troca é uma animação física, toda calculada num lugar só: cada aba tem um
/// progresso `p` (0 = recolhida, 1 = aberta) que vai pra 1 na aba nova e pra 0
/// na antiga, movido por uma mola; a largura de cada aba e a pílula de
/// seleção saem dessas mesmas contas, então os dois sempre combinam — nada de
/// o indicador correr num ritmo e os itens pularem em outro. As duas bordas da
/// pílula seguem molas diferentes: a da frente é firme e passa um tiquinho do
/// ponto, a de trás é mais macia e alcança depois, o que dá o efeito líquido,
/// com o alongamento limitado por [_maxStretch]. A cor da pílula também
/// escorre da seção antiga pra nova.
///
/// Além do toque, dá pra **arrastar o dedo pela barra**: a aba é a da zona onde
/// o dedo está (a largura da barra dividida em partes iguais, uma por aba) e
/// soltar deixa na última escolhida. Zonas iguais, e não os retângulos reais,
/// de propósito: a aba ativa é mais larga que as outras e muda de lugar a cada
/// troca, o que faria a seleção tremer na divisa entre duas abas. Cada troca
/// dá um toque de vibração leve.
class PillNavBar extends StatefulWidget {
  const PillNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<PillNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  State<PillNavBar> createState() => _PillNavBarState();
}

class _PillNavBarState extends State<PillNavBar>
    with SingleTickerProviderStateMixin {
  static const double _slotHeight = AppSpacing.minTapTarget;
  static const double _gap = AppSpacing.xs / 2;
  static const double _iconBox = 30;
  static const double _labelGap = AppSpacing.xs;
  static const double _padClosed = 10;
  static const double _padOpen = AppSpacing.md;

  /// O quanto a pílula pode passar da maior aba no meio da troca.
  static const double _maxStretch = 24;

  static const Duration _duration = Duration(milliseconds: 620);
  static final double _seconds = _duration.inMilliseconds / 1000;

  static final SpringSimulation _firm = SpringSimulation(
    SpringDescription.withDampingRatio(mass: 1, stiffness: 620, ratio: 0.78),
    0,
    1,
    0,
  );
  static final SpringSimulation _soft = SpringSimulation(
    SpringDescription.withDampingRatio(mass: 1, stiffness: 340, ratio: 0.92),
    0,
    1,
    0,
  );

  final _stackKey = GlobalKey();
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: _duration,
    value: 1,
  );

  late List<double> _p0;
  late List<double> _leftW0;
  late List<double> _rightW0;
  late Color _fromColor;
  bool _forward = true;
  int _target = 0;

  List<double> _textWidths = const [];
  TextStyle? _measuredStyle;
  TextScaler? _measuredScaler;

  @override
  void initState() {
    super.initState();
    _resetTo(widget.currentIndex);
  }

  void _resetTo(int index) {
    final n = widget.items.length;
    _target = index;
    _p0 = _oneHot(n, index);
    _leftW0 = _oneHot(n, index);
    _rightW0 = _oneHot(n, index);
    _fromColor = widget.items[index].color;
    _anim.value = 1;
  }

  List<double> _oneHot(int n, int index) =>
      [for (var i = 0; i < n; i++) i == index ? 1.0 : 0.0];

  @override
  void didUpdateWidget(covariant PillNavBar old) {
    super.didUpdateWidget(old);
    if (widget.items.length != old.items.length) {
      _resetTo(widget.currentIndex.clamp(0, widget.items.length - 1));
      return;
    }
    if (widget.currentIndex == _target) return;
    final now = _current();
    _p0 = now.p;
    _leftW0 = now.leftWeights;
    _rightW0 = now.rightWeights;
    _fromColor = now.color;
    _forward = widget.currentIndex > _target;
    _target = widget.currentIndex;
    _anim.forward(from: 0);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  double _spring(SpringSimulation sim) {
    final v = _anim.value;
    return v >= 1 ? 1.0 : sim.x(v * _seconds);
  }

  List<double> _toward(List<double> from, double s) => [
        for (var i = 0; i < from.length; i++)
          lerpDouble(from[i], i == _target ? 1 : 0, s)!,
      ];

  ({
    List<double> p,
    List<double> leftWeights,
    List<double> rightWeights,
    Color color,
  }) _current() {
    final firm = _spring(_firm);
    final soft = _spring(_soft);
    final p = [for (final v in _toward(_p0, firm)) math.max(0.0, v)];
    return (
      p: p,
      leftWeights: _toward(_leftW0, _forward ? soft : firm),
      rightWeights: _toward(_rightW0, _forward ? firm : soft),
      color: Color.lerp(
        _fromColor,
        widget.items[_target].color,
        firm.clamp(0.0, 1.0),
      )!,
    );
  }

  void _measure(BuildContext context) {
    final style = context.texts.labelLarge;
    final scaler = MediaQuery.textScalerOf(context);
    if (_textWidths.length == widget.items.length &&
        _measuredStyle == style &&
        _measuredScaler == scaler) {
      return;
    }
    _measuredStyle = style;
    _measuredScaler = scaler;
    _textWidths = [
      for (final item in widget.items)
        (TextPainter(
          text: TextSpan(text: item.label, style: style),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
          maxLines: 1,
        )..layout())
            .width
            .ceilToDouble(),
    ];
  }

  double _slotWidth(int i, double p) =>
      _iconBox +
      2 * lerpDouble(_padClosed, _padOpen, p.clamp(0.0, 1.0))! +
      p * (_labelGap + _textWidths[i]);

  /// Aba da zona onde o dedo está; seleciona e vibra só se for outra.
  void _scrubTo(Offset globalPosition) {
    final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || box.size.width <= 0) return;
    final dx = box.globalToLocal(globalPosition).dx;
    final count = widget.items.length;
    final index = (dx / box.size.width * count).floor().clamp(0, count - 1);
    if (index == widget.currentIndex) return;
    HapticFeedback.selectionClick();
    widget.onSelected(index);
  }

  Widget _buildBody(BuildContext context) {
    final state = _current();
    final n = widget.items.length;
    final widths = [for (var i = 0; i < n; i++) _slotWidth(i, state.p[i])];
    final lefts = <double>[];
    var x = 0.0;
    for (var i = 0; i < n; i++) {
      lefts.add(x);
      x += widths[i] + _gap;
    }

    var left = 0.0;
    var right = 0.0;
    for (var i = 0; i < n; i++) {
      left += state.leftWeights[i] * lefts[i];
      right += state.rightWeights[i] * (lefts[i] + widths[i]);
    }
    final widest = widths.reduce(math.max);
    if (right - left > widest + _maxStretch) {
      if (_forward) {
        left = right - (widest + _maxStretch);
      } else {
        right = left + (widest + _maxStretch);
      }
    }

    final total = x - _gap;
    left = left.clamp(0.0, total);
    right = right.clamp(left, total);

    return Stack(
      key: _stackKey,
      alignment: Alignment.centerLeft,
      children: [
        Positioned(
          left: left,
          top: 0,
          width: math.max(0, right - left),
          height: _slotHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: state.color,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < n; i++) ...[
              if (i > 0) const SizedBox(width: _gap),
              _NavSlot(
                item: widget.items[i],
                p: state.p[i],
                width: widths[i],
                textWidth: _textWidths[i],
                selected: i == widget.currentIndex,
                onTap: () => widget.onSelected(i),
              ),
            ],
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    _measure(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screen),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          boxShadow: [
            BoxShadow(
              color: colors.ink.withValues(alpha: 0.22),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: colors.ink,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          clipBehavior: Clip.antiAlias,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (d) => _scrubTo(d.globalPosition),
            onHorizontalDragUpdate: (d) => _scrubTo(d.globalPosition),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs / 2),
              child: AnimatedBuilder(
                animation: _anim,
                builder: (context, _) => _buildBody(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Uma aba: largura e conteúdo vêm do progresso [p] (0 recolhida, 1 aberta),
/// dado de fora — a aba não anima nada sozinha. O rótulo é revelado pela
/// própria largura da aba (com um fade) e o medalhão do ícone ganha cor e
/// tamanho junto. [p] passando um pouco de 1 (a mola) dá o estouro do ícone.
class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.item,
    required this.p,
    required this.width,
    required this.textWidth,
    required this.selected,
    required this.onTap,
  });

  final PillNavItem item;
  final double p;
  final double width;
  final double textWidth;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final open = p.clamp(0.0, 1.0);
    final onSection =
        item.color.computeLuminance() > 0.5 ? colors.ink : colors.onSaturated;
    final inactive = colors.onSaturated.withValues(alpha: 0.5);
    final foreground = Color.lerp(inactive, onSection, open)!;
    final medallion = Color.lerp(item.color, onSection, 0.18)!;
    final label = const Interval(0.35, 1).transform(open);

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: SizedBox(
        width: width,
        height: _PillNavBarState._slotHeight,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: 0,
              maxWidth: double.infinity,
              child: Padding(
                padding: EdgeInsets.only(
                  left: lerpDouble(
                    _PillNavBarState._padClosed,
                    _PillNavBarState._padOpen,
                    open,
                  )!,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: _PillNavBarState._iconBox,
                      height: _PillNavBarState._iconBox,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: medallion.withValues(alpha: open),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.icon,
                        size: lerpDouble(21, 17, p.clamp(0.0, 1.15))!,
                        color: foreground,
                      ),
                    ),
                    const SizedBox(width: _PillNavBarState._labelGap),
                    SizedBox(
                      width: textWidth,
                      child: Opacity(
                        opacity: label,
                        child: Text(
                          item.label,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: context.texts.labelLarge
                              ?.copyWith(color: foreground),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
