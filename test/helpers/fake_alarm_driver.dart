import 'package:receyta/data/services/alarm_driver.dart';

/// `AlarmDriver` de teste: não fala com plugin nenhum, só anota o que foi
/// pedido (`vibrate`, `vibrate(preview)`, `playSound`, `previewSound`,
/// `stopSound`, `stopVibration`).
class FakeAlarmDriver implements AlarmDriver {
  final calls = <String>[];

  @override
  Future<void> vibrate({bool preview = false}) async =>
      calls.add(preview ? 'vibrate(preview)' : 'vibrate');

  @override
  Future<void> playSound() async => calls.add('playSound');

  @override
  Future<void> previewSound() async => calls.add('previewSound');

  @override
  Future<void> stopSound() async => calls.add('stopSound');

  @override
  Future<void> stopVibration() async => calls.add('stopVibration');
}
