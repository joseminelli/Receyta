import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/data/services/alarm_driver.dart';
import 'package:receyta/features/recipes/controllers/cooking_alert_settings.dart';
import 'package:receyta/features/recipes/controllers/cooking_timers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_alarm_driver.dart';

void main() {
  late FakeAlarmDriver driver;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    driver = FakeAlarmDriver();
  });

  ProviderContainer newContainer() {
    final c = ProviderContainer(
      overrides: [alarmDriverProvider.overrideWithValue(driver)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('padrão: vibrar ligado e som desligado', () {
    final c = newContainer();
    expect(c.read(cookingAlertSettingsProvider), const CookingAlertSettings());
    expect(c.read(cookingAlertSettingsProvider).vibrate, isTrue);
    expect(c.read(cookingAlertSettingsProvider).sound, isFalse);
  });

  test('mudar fica salvo e volta igual na próxima abertura', () async {
    final first = newContainer();
    await first.read(cookingAlertSettingsProvider.notifier).setVibrate(false);
    await first.read(cookingAlertSettingsProvider.notifier).setSound(true);
    expect(first.read(cookingAlertSettingsProvider).vibrate, isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('cooking_alert_vibrate'), isFalse);
    expect(prefs.getBool('cooking_alert_sound'), isTrue);

    // "Reabre o app": container novo lê o que ficou no disco.
    final second = newContainer();
    second.read(cookingAlertSettingsProvider); // dispara a leitura
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(
      second.read(cookingAlertSettingsProvider),
      const CookingAlertSettings(vibrate: false, sound: true),
    );
  });

  test('cada chave é independente', () async {
    SharedPreferences.setMockInitialValues({'cooking_alert_sound': true});
    final c = newContainer();
    c.read(cookingAlertSettingsProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(
      c.read(cookingAlertSettingsProvider),
      const CookingAlertSettings(vibrate: true, sound: true),
    );
  });

  test('o alerta respeita as chaves: padrão, os dois, só toca, nenhum',
      () async {
    final c = newContainer();
    final notifier = c.read(cookingAlertSettingsProvider.notifier);
    final alert = c.read(cookingAlertProvider);

    alert(); // padrão: só vibra
    expect(driver.calls, ['vibrate']);

    driver.calls.clear();
    await notifier.setSound(true);
    alert();
    expect(driver.calls, ['vibrate', 'playSound']);

    driver.calls.clear();
    await notifier.setVibrate(false);
    alert();
    expect(driver.calls, ['playSound']);

    driver.calls.clear();
    await notifier.setSound(false);
    alert();
    expect(driver.calls, isEmpty);
  });

  test('mexer numa chave antes de ler o disco não faz a outra perder o salvo',
      () async {
    SharedPreferences.setMockInitialValues({'cooking_alert_sound': true});
    final c = newContainer();
    final notifier = c.read(cookingAlertSettingsProvider.notifier);
    // O usuário toca na vibração antes de a leitura terminar.
    await notifier.setVibrate(false);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(
      c.read(cookingAlertSettingsProvider),
      const CookingAlertSettings(vibrate: false, sound: true),
    );
  });
}
