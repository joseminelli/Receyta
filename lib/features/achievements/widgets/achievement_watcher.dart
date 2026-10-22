import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/features/achievements/controllers/achievements_view_model.dart';
import 'package:receyta/features/achievements/widgets/achievement_unlocked.dart';

/// Vigia o que alimenta as conquistas e comemora cada uma nova. Não desenha
/// nada: fica na raiz do app, reavalia (com uma pequena espera, pra juntar
/// mudanças seguidas) e mostra até [_maxPerCheck] comemorações em fila.
class AchievementWatcher extends ConsumerStatefulWidget {
  const AchievementWatcher({super.key});

  @override
  ConsumerState<AchievementWatcher> createState() => _AchievementWatcherState();
}

class _AchievementWatcherState extends ConsumerState<AchievementWatcher> {
  static const _maxPerCheck = 3;

  Timer? _debounce;
  bool _running = false;
  bool _again = false;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), _check);
  }

  Future<void> _check() async {
    if (!mounted) return;
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    try {
      final all = await loadAchievements(ref.read);
      final fresh = await takeNewAchievements(all);
      for (final a in fresh.take(_maxPerCheck)) {
        if (!mounted) break;
        await showAchievementUnlocked(a);
      }
    } catch (_) {
    } finally {
      _running = false;
      if (_again) {
        _again = false;
        _schedule();
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(achievementSignalProvider, (_, __) => _schedule());
    return const SizedBox.shrink();
  }
}
