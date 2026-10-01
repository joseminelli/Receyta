import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kVibrate = 'cooking_alert_vibrate';
const _kSound = 'cooking_alert_sound';

/// Como o timer avisa que acabou: vibrar e/ou tocar o som de alerta do
/// celular. As duas chaves moram na faixa de timers e ficam salvas no
/// aparelho. Por padrão só a vibração fica ligada: som sem pedir, na cozinha
/// de alguém ou num lugar quieto, é pior que vibrar; quem quer apito liga.
@immutable
class CookingAlertSettings {
  const CookingAlertSettings({this.vibrate = true, this.sound = false});

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

/// Lê as chaves direto do disco, sem Riverpod — é o que o segundo plano da
/// notificação usa (escolher o canal de aviso certo pra combinação vibrar/som).
Future<CookingAlertSettings> loadCookingAlertSettings() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return CookingAlertSettings(
      vibrate: prefs.getBool(_kVibrate) ?? true,
      sound: prefs.getBool(_kSound) ?? false,
    );
  } catch (_) {
    return const CookingAlertSettings();
  }
}

class CookingAlertSettingsNotifier extends Notifier<CookingAlertSettings> {
  /// Chaves que o usuário já mexeu antes da leitura do disco terminar: o que
  /// ele escolheu vale, e a leitura só preenche as que ele ainda não tocou
  /// (mexer numa não pode fazer a outra ficar no padrão pra sempre).
  bool _vibrateTouched = false;
  bool _soundTouched = false;

  @override
  CookingAlertSettings build() {
    _load();
    return const CookingAlertSettings();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = CookingAlertSettings(
        vibrate:
            _vibrateTouched ? state.vibrate : prefs.getBool(_kVibrate) ?? true,
        sound: _soundTouched ? state.sound : prefs.getBool(_kSound) ?? false,
      );
    } catch (e) {
      // Sem disco o padrão serve; só não persiste.
      debugPrint('CookingAlertSettings._load: $e');
    }
  }

  Future<void> setVibrate(bool on) async {
    _vibrateTouched = true;
    state = state.copyWith(vibrate: on);
    await _save(_kVibrate, on);
  }

  Future<void> setSound(bool on) async {
    _soundTouched = true;
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
