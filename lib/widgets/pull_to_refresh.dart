import 'package:flutter/material.dart';

import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/widgets/brand_loader.dart';

/// "Deslizar pra baixo pra atualizar" com o [BrandLoader] flutuando por cima
/// da lista — a lista em si não se move nem abre espaço nenhum (diferente do
/// `CupertinoSliverRefreshControl`, que empurra o conteúdo pra baixo pra
/// caber o indicador). Detecta o puxão via [OverscrollNotification], o mesmo
/// mecanismo do [RefreshIndicator] do Material — funciona com a física de
/// rolagem padrão, sem precisar de `BouncingScrollPhysics`.
///
/// O ícone acompanha o dedo conforme puxa (até um limite); ao soltar, some
/// de volta pro topo se não passou do ponto de gatilho, ou assenta num ponto
/// fixo — girando — enquanto [onRefresh] roda, e só então recolhe.
///
/// Envolve a `ScrollView` inteira (não é um sliver): `PullToRefreshControl(
/// onRefresh: ..., child: CustomScrollView(...))`.
class PullToRefreshControl extends StatefulWidget {
  const PullToRefreshControl({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  /// Os dados aqui já são reativos (Drift), então "atualizar" normalmente
  /// significa `ref.invalidate(...)` nos providers da tela — não tem
  /// servidor pra buscar de novo, é só uma reafirmação/força-atualização.
  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  State<PullToRefreshControl> createState() => _PullToRefreshControlState();
}

class _PullToRefreshControlState extends State<PullToRefreshControl> {
  /// Quanto precisa puxar pra soltar e disparar o refresh.
  static const _triggerDistance = 50.0;

  /// Até onde o ícone pode descer acompanhando o dedo (dá pra puxar mais
  /// que o gatilho, só não infinitamente).
  static const _maxPull = 60.0;

  /// Onde o ícone assenta enquanto [onRefresh] roda — sempre o mesmo ponto,
  /// não importa onde o dedo soltou entre o gatilho e o [_maxPull].
  static const _settleDistance = 54.0;

  /// Tempo mínimo parado no [_settleDistance] antes de recolher — sem isso,
  /// como os dados já são locais/reativos, [onRefresh] resolve quase
  /// instantâneo e o ícone nem dá tempo de parecer que atualizou de verdade.
  static const _minRefreshHold = Duration(milliseconds: 1000);

  double _pulled = 0;
  bool _dragging = false;
  bool _refreshing = false;

  /// Continua montado (com o ticker do [BrandLoader] rodando) enquanto tem
  /// alguma animação de entrada/saída em andamento — só desmonta de vez
  /// quando o recolhimento já terminou visualmente (via `onEnd`), nunca no
  /// mesmo frame que zera [_pulled]. Sem isso o ícone "sumia" ao soltar em
  /// vez de recolher suave.
  bool _showIndicator = false;

  bool _onNotification(ScrollNotification notification) {
    if (_refreshing) return false;

    if (notification is OverscrollNotification &&
        notification.metrics.extentBefore == 0 &&
        notification.overscroll < 0) {
      setState(() {
        _dragging = true;
        _showIndicator = true;
        _pulled = (_pulled - notification.overscroll).clamp(0.0, _maxPull);
      });
    } else if (notification is ScrollEndNotification) {
      _dragging = false;
      if (_pulled >= _triggerDistance) {
        _startRefresh();
      } else if (_pulled > 0) {
        setState(() => _pulled = 0);
      }
    }
    return false;
  }

  Future<void> _startRefresh() async {
    setState(() {
      _refreshing = true;
      _pulled = _settleDistance;
    });
    try {
      await Future.wait([
        widget.onRefresh(),
        Future.delayed(_minRefreshHold),
      ]);
    } finally {
      if (mounted) {
        setState(() {
          _refreshing = false;
          _pulled = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_pulled / _triggerDistance).clamp(0.0, 1.0);
    final visualProgress = _refreshing ? 1.0 : progress;

    // Mesma duração/curva pra posição, opacidade e escala — animando cada
    // uma num ritmo diferente é o que fica "robótico"; juntas, parece um
    // gesto só. Sem atraso enquanto o dedo ainda está arrastando.
    final duration =
        _dragging ? Duration.zero : const Duration(milliseconds: 260);
    const curve = Curves.easeOutCubic;

    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: Stack(
        children: [
          widget.child,
          if (_showIndicator)
            AnimatedPositioned(
              duration: duration,
              curve: curve,
              top: _pulled - 20,
              left: 0,
              right: 0,
              onEnd: () {
                // Só desmonta (parando o ticker do BrandLoader) depois que o
                // recolhimento já terminou visualmente na tela.
                if (_pulled == 0 && !_refreshing) {
                  setState(() => _showIndicator = false);
                }
              },
              child: IgnorePointer(
                child: Center(
                  child: AnimatedOpacity(
                    opacity: visualProgress,
                    duration: duration,
                    curve: curve,
                    child: AnimatedScale(
                      scale: 0.55 + visualProgress * 0.45,
                      duration: duration,
                      curve: curve,
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Degradê radial só pra destacar o ícone contra o
                            // conteúdo da lista atrás dele — some junto com ele.
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    context.colors.coral
                                        .withValues(alpha: 0.22),
                                    context.colors.coral.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                            BrandLoader(size: 26 + progress * 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
