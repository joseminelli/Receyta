import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/tokens.dart';
import '../controllers/mascot_mood_provider.dart';
import '../painters/cloche_painter.dart';
import '../painters/mascot_painter.dart';
import '../painters/mascot_pose.dart';
import '../painters/pote_painter.dart';

export '../controllers/mascot_mood_provider.dart' show MascotMood;

enum MascotKind {
  cloche(ClochePainter.designHeight),
  pote(PotePainter.designHeight);

  const MascotKind(this.designHeight);

  final double designHeight;
}

/// Mascote animado. Um único [Ticker] alimenta o painter, então mudar de humor
/// não reconstrói o widget; trocas de pose são suavizadas por uma mistura
/// curta. Com animações desativadas no sistema (ou fora de vista, via
/// `TickerMode`) fica parado.
///
/// O humor de base vem de [mood], ou do `mascotMoodProvider` do [scope] quando
/// há um (para a tela comandar vários mascotes). [greeting] toca uma vez na
/// entrada. Tocar no mascote o faz acenar ou pular — e, se estiver triste,
/// animar por um instante. [semanticLabel] só deve ser dado onde o mascote
/// carrega significado; sem ele, o mascote é decoração para leitores de tela.
class AnimatedMascot extends ConsumerStatefulWidget {
  const AnimatedMascot({
    super.key,
    required this.kind,
    this.width = 160,
    this.mood = MascotMood.idle,
    this.greeting,
    this.scope,
    this.tappable = true,
    this.semanticLabel,
  });

  final MascotKind kind;
  final double width;
  final MascotMood mood;
  final MascotMood? greeting;
  final String? scope;
  final bool tappable;
  final String? semanticLabel;

  @override
  ConsumerState<AnimatedMascot> createState() => _AnimatedMascotState();
}

class _AnimatedMascotState extends ConsumerState<AnimatedMascot>
    with SingleTickerProviderStateMixin {
  static const _blendSeconds = 0.2;

  final _seconds = ValueNotifier<double>(0);
  late final Ticker _ticker;
  late MascotMood _base;
  late MascotMood _mood;
  MascotMood? _transient;
  Timer? _transientTimer;
  int _taps = 0;
  double _moodStart = 0;
  MascotPose _from = MascotPose.rest;
  MascotPose _last = MascotPose.rest;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    final scope = widget.scope;
    _base = scope == null ? widget.mood : ref.read(mascotMoodProvider(scope));
    _mood = widget.greeting ?? _base;
    if (widget.greeting != null) _scheduleReturn(widget.greeting!);
    _ticker = createTicker((elapsed) {
      _seconds.value = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced) {
      _ticker.stop();
      _seconds.value = 0;
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(AnimatedMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scope == null && oldWidget.mood != widget.mood) {
      _base = widget.mood;
      _recompute();
    }
  }

  @override
  void dispose() {
    _transientTimer?.cancel();
    _ticker.dispose();
    _seconds.dispose();
    super.dispose();
  }

  double _durationOf(MascotMood mood) =>
      mood == MascotMood.celebrating ? celebrationSeconds : waveSeconds;

  void _scheduleReturn(MascotMood mood) {
    _transient = mood;
    _transientTimer?.cancel();
    _transientTimer = Timer(
      Duration(milliseconds: (_durationOf(mood) * 1000).round()),
      () {
        _transient = null;
        _recompute();
      },
    );
  }

  void _recompute({bool force = false}) {
    final next = _transient ?? _base;
    if (next == _mood && !force) return;
    _from = _last;
    _mood = next;
    _moodStart = _seconds.value;
  }

  void _react() {
    final next = _taps.isEven ? MascotMood.waving : MascotMood.celebrating;
    _taps++;
    _scheduleReturn(next);
    _recompute(force: true);
  }

  MascotPose _poseAt(double seconds) {
    if (_reduced) return MascotPose.rest;
    final local = seconds - _moodStart;
    final target = switch (_mood) {
      MascotMood.idle => idlePose(seconds),
      MascotMood.thinking => thinkingPose(seconds),
      MascotMood.waving => wavingPose(seconds),
      MascotMood.presenting => presentingPose(seconds),
      MascotMood.celebrating => celebratePose(local),
      MascotMood.sad => sadPose(seconds),
    };
    final blend = (local / _blendSeconds).clamp(0.0, 1.0);
    return _last = MascotPose.lerp(_from, target, blend);
  }

  @override
  Widget build(BuildContext context) {
    final scope = widget.scope;
    if (scope != null) {
      ref.listen(mascotMoodProvider(scope), (_, next) {
        _base = next;
        _recompute();
      });
    }
    final colors = Theme.of(context).extension<AppColors>()!;
    final MascotPainter painter = switch (widget.kind) {
      MascotKind.cloche => ClochePainter(
          colors: colors,
          seconds: _seconds,
          poseAt: _poseAt,
        ),
      MascotKind.pote => PotePainter(
          colors: colors,
          seconds: _seconds,
          poseAt: _poseAt,
        ),
    };
    final art = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.tappable ? _react : null,
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size(
            widget.width,
            widget.width * widget.kind.designHeight / MascotPainter.designWidth,
          ),
          painter: painter,
        ),
      ),
    );
    final label = widget.semanticLabel;
    if (label == null) return ExcludeSemantics(child: art);
    return Semantics(
      label: label,
      image: true,
      excludeSemantics: true,
      child: art,
    );
  }
}
