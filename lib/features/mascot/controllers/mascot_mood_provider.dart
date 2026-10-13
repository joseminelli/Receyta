import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../painters/mascot_pose.dart';

enum MascotMood { idle, thinking, waving, celebrating }

/// Humor dos mascotes na tela. `waving` e `celebrating` duram o tempo da
/// animação e voltam sozinhos para `idle`; `thinking` fica até alguém chamar
/// [stopThinking].
class MascotMoodNotifier extends Notifier<MascotMood> {
  Timer? _timer;

  @override
  MascotMood build() {
    ref.onDispose(() => _timer?.cancel());
    return MascotMood.idle;
  }

  void think() {
    if (state == MascotMood.celebrating || state == MascotMood.waving) return;
    state = MascotMood.thinking;
  }

  void stopThinking() {
    if (state == MascotMood.thinking) state = MascotMood.idle;
  }

  void wave() => _timed(MascotMood.waving, waveSeconds);

  void celebrate() => _timed(MascotMood.celebrating, celebrationSeconds);

  void _timed(MascotMood mood, double seconds) {
    _timer?.cancel();
    if (state == mood) state = MascotMood.idle;
    state = mood;
    _timer = Timer(
      Duration(milliseconds: (seconds * 1000).round()),
      () => state = MascotMood.idle,
    );
  }
}

final mascotMoodProvider =
    NotifierProvider<MascotMoodNotifier, MascotMood>(MascotMoodNotifier.new);
