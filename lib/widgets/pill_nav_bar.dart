import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:receyta/core/tile_style.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/tab_motion.dart';

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
/// Tudo nasce de uma posição fracionária única, a do [TabMotion]: a "abertura"
/// de cada aba (0 recolhida, 1 aberta) é um triângulo em volta dessa posição,
/// então entre duas abas uma fecha enquanto a outra abre, e a largura das
/// abas, a pílula de seleção e a cor saem das mesmas contas — sempre combinam.
/// As duas bordas da pílula usam as duas posições do [TabMotion] (a da frente
/// é firme, a de trás é macia): daí o efeito líquido, com o alongamento
/// limitado por [_maxStretch]. A posição vem de uma mola nas trocas por toque
/// e **segue o dedo** quando se arrasta a barra: a pílula acompanha antes de
/// soltar e, ao soltar, assenta na aba mais próxima.
///
/// O arrasto mapeia o dedo em zonas iguais (a largura da barra dividida por
/// aba) em vez dos retângulos reais: a aba ativa é mais larga que as outras e
/// muda de lugar a cada troca, o que faria a seleção tremer na divisa. Cada
/// vez que o dedo passa a estar sobre outra aba, um toque leve de vibração.
///
/// Passando um [motion], quem chama pode ler a mesma posição (a faixa de
/// páginas, por exemplo); sem ele, a barra cria o seu.
class PillNavBar extends StatefulWidget {
  const PillNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
    this.motion,
  });

  final List<PillNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;
  final TabMotion? motion;

  @override
  State<PillNavBar> createState() => _PillNavBarState();
}

class _PillNavBarState extends State<PillNavBar> with TickerProviderStateMixin {
  static const double _slotHeight = AppSpacing.minTapTarget;
  static const double _gap = AppSpacing.xs / 2;
  static const double _iconBox = 30;
  static const double _labelGap = AppSpacing.xs;
  static const double _padClosed = 10;
  static const double _padOpen = AppSpacing.md;

  /// O quanto a pílula pode passar da maior aba no meio da troca.
  static const double _maxStretch = 24;

  final _stackKey = GlobalKey();
  TabMotion? _ownMotion;
  int _dragIndex = 0;

  List<double> _textWidths = const [];
  TextStyle? _measuredStyle;
  TextScaler? _measuredScaler;

  TabMotion get _motion => widget.motion ?? _ownMotion!;

  @override
  void initState() {
    super.initState();
    if (widget.motion == null) {
      _ownMotion = TabMotion(
        vsync: this,
        count: widget.items.length,
        initial: widget.currentIndex,
      );
    }
  }

  @override
  void didUpdateWidget(covariant PillNavBar old) {
    super.didUpdateWidget(old);
    if (widget.currentIndex != old.currentIndex &&
        !_motion.dragging &&
        _motion.target != widget.currentIndex) {
      _motion.animateTo(widget.currentIndex);
    }
  }

  @override
  void dispose() {
    _ownMotion?.dispose();
    super.dispose();
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

  /// Abertura (0 a 1) da aba [i] com a seleção na posição [pos].
  double _open(double pos, int i) => (1 - (pos - i).abs()).clamp(0.0, 1.0);

  double _slotWidth(int i, double open) =>
      _iconBox +
      2 * lerpDouble(_padClosed, _padOpen, open)! +
      open * (_labelGap + _textWidths[i]);

  /// Posição (em abas) do dedo, mapeando a largura da barra em zonas iguais.
  double? _positionAt(Offset globalPosition) {
    final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || box.size.width <= 0) return null;
    final dx = box.globalToLocal(globalPosition).dx;
    final count = widget.items.length;
    return dx / box.size.width * count - 0.5;
  }

  void _dragStart(DragStartDetails d) {
    _dragIndex = widget.currentIndex;
    _dragMove(d.globalPosition);
  }

  void _dragMove(Offset globalPosition) {
    final pos = _positionAt(globalPosition);
    if (pos == null) return;
    _motion.dragTo(pos);
    final index = _motion.lead.round().clamp(0, widget.items.length - 1);
    if (index != _dragIndex) {
      _dragIndex = index;
      HapticFeedback.selectionClick();
    }
  }

  void _dragEnd(DragEndDetails d) {
    final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final perTab = box == null ? 0.0 : box.size.width / widget.items.length;
    final velocity = perTab <= 0
        ? 0.0
        : (d.velocity.pixelsPerSecond.dx / perTab).clamp(-6.0, 6.0);
    final index = _motion.lead.round().clamp(0, widget.items.length - 1);
    _motion.animateTo(index, velocity: velocity);
    if (index != widget.currentIndex) widget.onSelected(index);
  }

  Widget _buildBody(BuildContext context) {
    final n = widget.items.length;
    final lead = _motion.lead.clamp(0.0, n - 1.0);
    final trail = _motion.trail.clamp(0.0, n - 1.0);
    final front = math.max(lead, trail);
    final back = math.min(lead, trail);

    final opens = [for (var i = 0; i < n; i++) _open(lead, i)];
    final widths = [for (var i = 0; i < n; i++) _slotWidth(i, opens[i])];
    final lefts = <double>[];
    var x = 0.0;
    for (var i = 0; i < n; i++) {
      lefts.add(x);
      x += widths[i] + _gap;
    }
    final total = x - _gap;

    var left = 0.0;
    var right = 0.0;
    for (var i = 0; i < n; i++) {
      left += _open(back, i) * lefts[i];
      right += _open(front, i) * (lefts[i] + widths[i]);
    }
    final cap = widths.reduce(math.max) + _maxStretch;
    if (right - left > cap) {
      if (lead >= trail) {
        left = right - cap;
      } else {
        right = left + cap;
      }
    }
    left = left.clamp(0.0, total);
    right = right.clamp(left, total);

    final base = lead.floor().clamp(0, n - 1);
    final next = math.min(base + 1, n - 1);
    final color = Color.lerp(
      widget.items[base].color,
      widget.items[next].color,
      lead - base,
    )!;

    return Stack(
      key: _stackKey,
      alignment: Alignment.centerLeft,
      children: [
        Positioned(
          left: left,
          top: 0,
          width: right - left,
          height: _slotHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
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
                open: opens[i],
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
            onHorizontalDragStart: _dragStart,
            onHorizontalDragUpdate: (d) => _dragMove(d.globalPosition),
            onHorizontalDragEnd: _dragEnd,
            onHorizontalDragCancel: () =>
                _motion.animateTo(widget.currentIndex),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs / 2),
              child: AnimatedBuilder(
                animation: _motion.listenable,
                builder: (context, _) => _buildBody(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Uma aba: largura e conteúdo vêm da abertura [open] (0 recolhida, 1 aberta),
/// dada de fora — a aba não anima nada sozinha. O rótulo é revelado pela
/// própria largura da aba (com um fade) e o medalhão do ícone ganha cor e
/// tamanho junto.
class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.item,
    required this.open,
    required this.width,
    required this.textWidth,
    required this.selected,
    required this.onTap,
  });

  final PillNavItem item;
  final double open;
  final double width;
  final double textWidth;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
                        size: lerpDouble(21, 17, open)!,
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
