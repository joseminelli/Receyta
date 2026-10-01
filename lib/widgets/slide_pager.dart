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
  State<SlidePager> createState() => SlidePagerState();
}

/// Estado público pra que outra área (ex.: o cabeçalho da tela do dia) possa
/// puxar o mesmo arrasto via `GlobalKey<SlidePagerState>` — `handleDrag*`.
///
/// Desempenho: o deslocamento mora num [ValueNotifier] e só o `Transform` das
/// páginas escuta — o conteúdo delas não é reconstruído a cada movimento do
/// dedo (só quando a página vizinha entra ou sai). Cada página fica numa
/// camada própria ([RepaintBoundary]), então mover é só transformar a camada.
class SlidePagerState extends State<SlidePager>
    with SingleTickerProviderStateMixin {
  static const _settleDuration = Duration(milliseconds: 240);
  static const _commitFraction = 0.3;
  static const _commitVelocity = 700.0;

  late final AnimationController _settle;
  late final ValueNotifier<double> _drag;

  double _width = 0;
  bool _settling = false;

  /// Qual vizinha está desenhada: 1 = a próxima (arrasto pra esquerda),
  /// -1 = a anterior, 0 = nenhuma.
  int _neighborDir = 0;

  /// Logo depois de uma página passada com o dedo, a troca de índice não
  /// pode animar de novo (a página nova já está na tela).
  bool _instant = false;

  @override
  void initState() {
    super.initState();
    // No initState, não lazy: um `late final` criado só no dispose tenta
    // abrir um Ticker com o elemento já desativado.
    _settle = AnimationController(vsync: this, duration: _settleDuration);
    _drag = ValueNotifier<double>(0);
  }

  @override
  void dispose() {
    _settle.dispose();
    _drag.dispose();
    super.dispose();
  }

  void _setNeighbor(int dir) {
    if (dir != _neighborDir) setState(() => _neighborDir = dir);
  }

  void handleDragUpdate(DragUpdateDetails d) {
    if (_settling || _width == 0) return;
    final x = (_drag.value + d.delta.dx).clamp(-_width, _width);
    _setNeighbor(x < 0 ? 1 : (x > 0 ? -1 : 0));
    _drag.value = x;
  }

  void handleDragEnd(DragEndDetails d) {
    if (_settling || _drag.value == 0) return;
    final velocity = d.primaryVelocity ?? 0;
    final forward = _drag.value < 0;
    final far = _drag.value.abs() > _width * _commitFraction;
    final fast = velocity.abs() > _commitVelocity && (velocity < 0) == forward;
    final commit = far || fast;
    _settleTo(commit ? (forward ? -_width : _width) : 0, commit, forward);
  }

  void handleDragCancel() {
    if (!_settling && _drag.value != 0) _settleTo(0, false, true);
  }

  void _settleTo(double target, bool commit, bool forward) {
    _settling = true;
    final curved = CurvedAnimation(
      parent: _settle,
      curve: Curves.easeOutCubic,
    );
    final tween = Tween<double>(begin: _drag.value, end: target);
    void tick() => _drag.value = tween.evaluate(curved);
    curved.addListener(tick);
    _settle.forward(from: 0).whenComplete(() {
      curved.removeListener(tick);
      curved.dispose();
      if (!mounted) return;
      if (commit) {
        _instant = true;
        _drag.value = 0;
        setState(() {
          _neighborDir = 0;
          _settling = false;
        });
        widget.onChanged(widget.index + (forward ? 1 : -1));
        WidgetsBinding.instance.addPostFrameCallback((_) => _instant = false);
      } else {
        _drag.value = 0;
        setState(() {
          _neighborDir = 0;
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

        Widget neighborPage(int dir) {
          final page = RepaintBoundary(
            child: KeyedSubtree(
              key: ValueKey('pager-neighbor-${widget.index + dir}'),
              child: widget.builder(widget.index + dir),
            ),
          );
          return Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: _width,
            child: ValueListenableBuilder<double>(
              valueListenable: _drag,
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
              builder: (context, x, child) => Transform.translate(
                offset: Offset(x + (dir > 0 ? _width : -_width), 0),
                child: child,
              ),
            ),
          );
        }

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: handleDragUpdate,
          onHorizontalDragEnd: handleDragEnd,
          onHorizontalDragCancel: handleDragCancel,
          child: ClipRect(
            child: Stack(
              children: [
                if (_neighborDir != 0) neighborPage(_neighborDir),
                ValueListenableBuilder<double>(
                  valueListenable: _drag,
                  child: RepaintBoundary(
                    child: SlideSwitcher(
                      key: const ValueKey('pager-current'),
                      index: widget.index,
                      duration: _instant
                          ? Duration.zero
                          : const Duration(milliseconds: 280),
                      child: widget.builder(widget.index),
                    ),
                  ),
                  builder: (context, x, child) =>
                      Transform.translate(offset: Offset(x, 0), child: child),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
