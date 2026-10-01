import 'package:flutter/material.dart';

import 'package:receyta/widgets/slide_switcher.dart';

/// Páginas que se passam com o dedo (mês, dia). Arrastar na horizontal move a
/// página junto com o dedo e mostra a vizinha entrando; ao soltar, passa se o
/// arrasto foi longe ou rápido o bastante, senão volta. Quando o [index] muda
/// por fora (botão, seta) o [SlideSwitcher] faz o deslize sozinho — os dois
/// caminhos terminam no mesmo lugar sem animar duas vezes.
///
/// [builder] monta a página de qualquer índice (a atual e a vizinha);
/// [onChanged] recebe o índice novo quando o arrasto passa de página.
class SlidePager extends StatefulWidget {
  const SlidePager({
    super.key,
    required this.index,
    required this.builder,
    required this.onChanged,
  });

  final int index;
  final Widget Function(int index) builder;
  final ValueChanged<int> onChanged;

  @override
  State<SlidePager> createState() => _SlidePagerState();
}

class _SlidePagerState extends State<SlidePager>
    with SingleTickerProviderStateMixin {
  static const _settleDuration = Duration(milliseconds: 240);
  static const _commitFraction = 0.3;
  static const _commitVelocity = 700.0;

  late final AnimationController _settle;

  double _dragX = 0;
  double _width = 0;
  bool _settling = false;

  /// Logo depois de uma página passada com o dedo, a troca de índice não
  /// pode animar de novo (a página nova já está na tela).
  bool _instant = false;

  @override
  void initState() {
    super.initState();
    // No initState, não lazy: um `late final` criado só no dispose tenta
    // abrir um Ticker com o elemento já desativado.
    _settle = AnimationController(vsync: this, duration: _settleDuration);
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  void _onUpdate(DragUpdateDetails d) {
    if (_settling || _width == 0) return;
    setState(() => _dragX = (_dragX + d.delta.dx).clamp(-_width, _width));
  }

  void _onEnd(DragEndDetails d) {
    if (_settling || _dragX == 0) return;
    final velocity = d.primaryVelocity ?? 0;
    final forward = _dragX < 0;
    final far = _dragX.abs() > _width * _commitFraction;
    final fast = velocity.abs() > _commitVelocity && (velocity < 0) == forward;
    final commit = far || fast;
    _settleTo(commit ? (forward ? -_width : _width) : 0, commit, forward);
  }

  void _settleTo(double target, bool commit, bool forward) {
    _settling = true;
    final curved = CurvedAnimation(
      parent: _settle,
      curve: Curves.easeOutCubic,
    );
    final tween = Tween<double>(begin: _dragX, end: target);
    void tick() => setState(() => _dragX = tween.evaluate(curved));
    curved.addListener(tick);
    _settle.forward(from: 0).whenComplete(() {
      curved.removeListener(tick);
      curved.dispose();
      if (!mounted) return;
      if (commit) {
        _instant = true;
        setState(() {
          _dragX = 0;
          _settling = false;
        });
        widget.onChanged(widget.index + (forward ? 1 : -1));
        WidgetsBinding.instance.addPostFrameCallback((_) => _instant = false);
      } else {
        setState(() {
          _dragX = 0;
          _settling = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _width = constraints.maxWidth;
        final bounded = constraints.hasBoundedHeight;
        final neighbor =
            _dragX == 0 ? null : widget.index + (_dragX < 0 ? 1 : -1);

        Widget neighborPage(int index) {
          final page = KeyedSubtree(
            key: ValueKey('pager-neighbor-$index'),
            child: widget.builder(index),
          );
          return Positioned(
            left: _dragX + (_dragX < 0 ? _width : -_width),
            top: 0,
            bottom: 0,
            width: _width,
            // Em altura livre (dentro de uma lista) a vizinha pode ser mais
            // alta que a atual: deixa crescer em vez de estourar o layout.
            child: bounded
                ? page
                : OverflowBox(
                    alignment: Alignment.topCenter,
                    minHeight: 0,
                    maxHeight: double.infinity,
                    child: page,
                  ),
          );
        }

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: _onUpdate,
          onHorizontalDragEnd: _onEnd,
          onHorizontalDragCancel: () {
            if (!_settling && _dragX != 0) _settleTo(0, false, true);
          },
          child: ClipRect(
            child: Stack(
              children: [
                if (neighbor != null) neighborPage(neighbor),
                Transform.translate(
                  offset: Offset(_dragX, 0),
                  child: SlideSwitcher(
                    key: const ValueKey('pager-current'),
                    index: widget.index,
                    duration: _instant
                        ? Duration.zero
                        : const Duration(milliseconds: 280),
                    child: widget.builder(widget.index),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
