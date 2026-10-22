import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// A posição (fracionária) da seleção entre as abas, num lugar só: a
/// `PillNavBar` e a faixa de páginas leem daqui, então a pílula e o deslize das
/// telas sempre andam juntos — seja numa troca por toque (mola) ou enquanto o
/// dedo arrasta a barra.
///
/// Há duas posições com molas diferentes. [lead] é firme e passa um tiquinho
/// do destino (é a borda da frente da pílula); [trail] é mais macia e quase
/// não passa (a borda de trás da pílula e as páginas, que não podem deixar
/// vão). Trocar no meio de uma troca recomeça de onde está, com a velocidade
/// que já tinha, então não há salto.
class TabMotion {
  TabMotion(
      {required TickerProvider vsync, required this.count, int initial = 0})
      : _target = initial,
        _lead = AnimationController.unbounded(
          vsync: vsync,
          value: initial.toDouble(),
        ),
        _trail = AnimationController.unbounded(
          vsync: vsync,
          value: initial.toDouble(),
        );

  /// Quantas abas há; as posições úteis vão de 0 a `count - 1`.
  final int count;

  static final SpringDescription _firm = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 620,
    ratio: 0.78,
  );
  static final SpringDescription _soft = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 420,
    ratio: 0.95,
  );

  final AnimationController _lead;
  final AnimationController _trail;
  int _target;
  bool _dragging = false;

  double get lead => _lead.value;
  double get trail => _trail.value;

  /// A aba pra onde a seleção está indo (ou parada nela).
  int get target => _target;

  /// O dedo está arrastando a barra: a posição segue o dedo, sem mola.
  bool get dragging => _dragging;

  Listenable get listenable => Listenable.merge([_lead, _trail]);

  /// Anima até a aba [index]. [velocity] é a velocidade atual em abas por
  /// segundo (ao soltar um arrasto), pra a mola continuar o movimento do dedo.
  void animateTo(int index, {double velocity = 0}) {
    final to = index.clamp(0, count - 1).toDouble();
    _dragging = false;
    _target = to.round();
    _lead.animateWith(SpringSimulation(_firm, _lead.value, to, velocity));
    _trail.animateWith(SpringSimulation(_soft, _trail.value, to, velocity));
  }

  /// Põe a seleção na posição [position] (em abas, fracionária), seguindo o
  /// dedo.
  void dragTo(double position) {
    _dragging = true;
    final p = position.clamp(0.0, count - 1.0);
    _lead.stop();
    _trail.stop();
    _lead.value = p;
    _trail.value = p;
  }

  void dispose() {
    _lead.dispose();
    _trail.dispose();
  }
}
