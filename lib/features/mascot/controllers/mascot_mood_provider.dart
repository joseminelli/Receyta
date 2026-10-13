import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../painters/mascot_pose.dart';

enum MascotMood { idle, thinking, waving, presenting, celebrating, sad }

/// Humor de um grupo de mascotes, identificado por um escopo (o nome da tela).
/// Mascotes de telas diferentes não se influenciam. `waving` e `celebrating`
/// duram o tempo da animação e voltam sozinhos para `idle`; `thinking` fica
/// até alguém chamar [stopThinking].
class MascotMoodNotifier extends FamilyNotifier<MascotMood, String> {
  Timer? _timer;

  @override
  MascotMood build(String arg) {
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
    NotifierProvider.family<MascotMoodNotifier, MascotMood, String>(
  MascotMoodNotifier.new,
);
