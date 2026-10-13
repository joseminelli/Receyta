import 'dart:async';

import 'package:flutter/material.dart';

import '../../../messenger.dart';
import '../painters/mascot_pose.dart';
import 'animated_mascot.dart';

/// Mostra um mascote por cima de tudo por alguns segundos — comemorando uma
/// conquista ou acenando — e o tira sozinho. Não bloqueia toques e não precisa
/// de `BuildContext`: acha o `Overlay` raiz, como o `showAppSnackBar`.
void showMascotMoment({
  required MascotKind kind,
  MascotMood mood = MascotMood.celebrating,
  double width = 112,
}) {
  final overlay = rootNavigatorKey.currentState?.overlay;
  if (overlay == null) return;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _MascotMoment(
      kind: kind,
      mood: mood,
      width: width,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _MascotMoment extends StatefulWidget {
  const _MascotMoment({
    required this.kind,
    required this.mood,
    required this.width,
    required this.onDone,
  });

  final MascotKind kind;
  final MascotMood mood;
  final double width;
  final VoidCallback onDone;

  @override
  State<_MascotMoment> createState() => _MascotMomentState();
}

class _MascotMomentState extends State<_MascotMoment> {
  static const _fade = Duration(milliseconds: 250);

  bool _visible = false;
  Timer? _hold;
  Timer? _remove;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
    final seconds =
        widget.mood == MascotMood.celebrating ? celebrationSeconds : waveSeconds;
    _hold = Timer(
      Duration(milliseconds: (seconds * 1000).round() + 300),
      () {
        if (mounted) setState(() => _visible = false);
        _remove = Timer(_fade, widget.onDone);
      },
    );
  }

  @override
  void dispose() {
    _hold?.cancel();
    _remove?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 112;
    return Positioned(
      left: 0,
      right: 0,
      bottom: bottom,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: _visible ? 1 : 0,
          duration: _fade,
          child: Center(
            child: AnimatedMascot(
              kind: widget.kind,
              width: widget.width,
              greeting: widget.mood,
              tappable: false,
            ),
          ),
        ),
      ),
    );
  }
}
