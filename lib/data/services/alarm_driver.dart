import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:vibration/vibration.dart';

/// Vibrar e tocar som de verdade no aparelho — a ponte pros plugins. Existe
/// como interface pra o resto do app (e os testes) não falarem com plugin.
///
/// Por que não `HapticFeedback`/`SystemSound` do Flutter: no Android o
/// `SystemSound.play(alert)` só toca o "clique" do sistema (e só com os sons de
/// toque ligados) e o `HapticFeedback.vibrate()` é um toque curtíssimo que
/// muita configuração desliga — não servem de alarme de timer.
abstract class AlarmDriver {
  /// Vibração longa de alarme (ou a curta de amostra, em [preview]).
  Future<void> vibrate({bool preview = false});

  /// Toca o alarme padrão do aparelho, uma vez, no volume de alarme.
  Future<void> playSound();

  /// Amostra curta do som, pra quem acabou de ligar a chave.
  Future<void> previewSound();

  /// Para o som que estiver tocando.
  Future<void> stopSound();

  /// Para a vibração em andamento.
  Future<void> stopVibration();
}

class PluginAlarmDriver implements AlarmDriver {
  static const _alarmPattern = [0, 700, 300, 700, 300, 700];

  @override
  Future<void> vibrate({bool preview = false}) async {
    try {
      if (await Vibration.hasVibrator() == true) {
        if (preview) {
          await Vibration.vibrate(duration: 250);
        } else {
          await Vibration.vibrate(pattern: _alarmPattern);
        }
        return;
      }
    } catch (e) {
      debugPrint('AlarmDriver.vibrate: $e');
    }
    // Sem o plugin/aparelho sem motor: ao menos o toque curto do sistema.
    try {
      await HapticFeedback.vibrate();
    } catch (_) {}
  }

  @override
  Future<void> playSound() async {
    try {
      await FlutterRingtonePlayer().playAlarm(
        looping: false,
        asAlarm: true,
        volume: 1,
      );
    } catch (e) {
      debugPrint('AlarmDriver.playSound: $e');
    }
  }

  @override
  Future<void> previewSound() async {
    try {
      // Antes de tocar a amostra, corta o que estiver tocando: ligar e
      // desligar rápido não pode empilhar sons.
      await FlutterRingtonePlayer().stop();
      await FlutterRingtonePlayer().playNotification(
        looping: false,
        asAlarm: false,
      );
    } catch (e) {
      debugPrint('AlarmDriver.previewSound: $e');
    }
  }

  @override
  Future<void> stopVibration() async {
    try {
      await Vibration.cancel();
    } catch (e) {
      debugPrint('AlarmDriver.stopVibration: $e');
    }
  }

  @override
  Future<void> stopSound() async {
    try {
      await FlutterRingtonePlayer().stop();
    } catch (e) {
      debugPrint('AlarmDriver.stopSound: $e');
    }
  }
}

/// O driver de verdade; os testes trocam por um falso.
final alarmDriverProvider = Provider<AlarmDriver>((ref) => PluginAlarmDriver());
