import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kVibrate = 'cooking_alert_vibrate';
const _kSound = 'cooking_alert_sound';

/// Como o timer avisa que acabou: vibrar e/ou tocar o som de alerta do
/// celular. As duas chaves moram na faixa de timers e ficam salvas no
/// aparelho. Por padrão as duas ligadas — timer que passa batido é pior que
/// timer que apita onde não devia.
@immutable
class CookingAlertSettings {
  const CookingAlertSettings({this.vibrate = true, this.sound = true});

  final bool vibrate;
  final bool sound;

  CookingAlertSettings copyWith({bool? vibrate, bool? sound}) =>
      CookingAlertSettings(
        vibrate: vibrate ?? this.vibrate,
        sound: sound ?? this.sound,
      );

  @override
  bool operator ==(Object other) =>
      other is CookingAlertSettings &&
      other.vibrate == vibrate &&
      other.sound == sound;

  @override
  int get hashCode => Object.hash(vibrate, sound);
}

class CookingAlertSettingsNotifier extends Notifier<CookingAlertSettings> {
  /// O usuário mexeu antes da leitura do disco terminar: o que ele escolheu
  /// vale, a leitura não sobrescreve.
  bool _touched = false;

  @override
  CookingAlertSettings build() {
    _load();
    return const CookingAlertSettings();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_touched) return;
      state = CookingAlertSettings(
        vibrate: prefs.getBool(_kVibrate) ?? true,
        sound: prefs.getBool(_kSound) ?? true,
      );
    } catch (e) {
      // Sem disco o padrão serve; só não persiste.
      debugPrint('CookingAlertSettings._load: $e');
    }
  }

  Future<void> setVibrate(bool on) async {
    _touched = true;
    state = state.copyWith(vibrate: on);
    await _save(_kVibrate, on);
  }

  Future<void> setSound(bool on) async {
    _touched = true;
    state = state.copyWith(sound: on);
    await _save(_kSound, on);
  }

  Future<void> _save(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('CookingAlertSettings._save: $e');
    }
  }
}

final cookingAlertSettingsProvider =
    NotifierProvider<CookingAlertSettingsNotifier, CookingAlertSettings>(
  CookingAlertSettingsNotifier.new,
);
