import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receyta/domain/models/cooking_timer.dart';

/// Onde os timers do modo cozinha ficam guardados no aparelho. É a ponte entre
/// o app e os botões da notificação: com o app minimizado, "Pausar" e "Parar"
/// rodam num isolate à parte, sem acesso ao estado da tela, e só enxergam
/// isto aqui.
abstract class TimersStore {
  /// A lista guardada, ou `null` se nunca se guardou nada (ou o registro está
  /// ilegível) — assim "lista vazia" (todos cancelados) e "nada guardado" não
  /// se confundem.
  Future<List<CookingTimer>?> load();

  Future<void> save(List<CookingTimer> timers);
}

class PrefsTimersStore implements TimersStore {
  static const key = 'cooking_timers_v1';

  @override
  Future<List<CookingTimer>?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Outro isolate (a notificação) pode ter escrito: relê do disco.
      await prefs.reload();
      final raw = prefs.getString(key);
      if (raw == null) return null;
      final out = <CookingTimer>[];
      for (final item in jsonDecode(raw) as List<Object?>) {
        if (item is! Map) continue;
        final t = CookingTimer.fromJson(item.cast<String, Object?>());
        if (t != null) out.add(t);
      }
      return out;
    } catch (e) {
      debugPrint('TimersStore.load: $e');
      return null;
    }
  }

  @override
  Future<void> save(List<CookingTimer> timers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        key,
        jsonEncode([for (final t in timers) t.toJson()]),
      );
    } catch (e) {
      debugPrint('TimersStore.save: $e');
    }
  }
}

final timersStoreProvider = Provider<TimersStore>((ref) => PrefsTimersStore());
