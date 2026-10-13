import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/tokens.dart';
import '../controllers/mascot_mood_provider.dart';
import '../painters/cloche_painter.dart';
import '../painters/mascot_painter.dart';
import '../painters/mascot_pose.dart';
import '../painters/pote_painter.dart';

enum MascotKind {
  cloche(ClochePainter.designHeight),
  pote(PotePainter.designHeight);

  const MascotKind(this.designHeight);

  final double designHeight;
}

/// Mascote animado, reativo ao `mascotMoodProvider`. Um único [Ticker] alimenta
/// o painter, então mudar de humor não reconstrói o widget; trocas de pose são
/// suavizadas por uma mistura curta. Com animações desativadas no sistema (ou
/// fora de vista, via `TickerMode`) fica parado.
class AnimatedMascot extends ConsumerStatefulWidget {
  const AnimatedMascot({super.key, required this.kind, this.width = 160});

  final MascotKind kind;
  final double width;

  @override
  ConsumerState<AnimatedMascot> createState() => _AnimatedMascotState();
}

class _AnimatedMascotState extends ConsumerState<AnimatedMascot>
    with SingleTickerProviderStateMixin {
  static const _blendSeconds = 0.2;

  final _seconds = ValueNotifier<double>(0);
  late final Ticker _ticker;
  late MascotMood _mood;
  double _moodStart = 0;
  MascotPose _from = MascotPose.rest;
  MascotPose _last = MascotPose.rest;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    _mood = ref.read(mascotMoodProvider);
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
  void dispose() {
    _ticker.dispose();
    _seconds.dispose();
    super.dispose();
  }

  MascotPose _poseAt(double seconds) {
    if (_reduced) return MascotPose.rest;
    final local = seconds - _moodStart;
    final target = switch (_mood) {
      MascotMood.idle => idlePose(seconds),
      MascotMood.thinking => thinkingPose(seconds),
      MascotMood.waving => wavingPose(seconds),
      MascotMood.celebrating => celebratePose(local),
    };
    final blend = (local / _blendSeconds).clamp(0.0, 1.0);
    return _last = MascotPose.lerp(_from, target, blend);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(mascotMoodProvider, (_, next) {
      _from = _last;
      _mood = next;
      _moodStart = _seconds.value;
    });
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
    return ExcludeSemantics(
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
  }
}
