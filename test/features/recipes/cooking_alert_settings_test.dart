import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/features/recipes/controllers/cooking_alert_settings.dart';
import 'package:receyta/features/recipes/controllers/cooking_timers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Conta o que o alerta de verdade manda pro sistema.
  late List<String> platformCalls;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    platformCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      platformCalls.add(call.method);
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });
  });

  ProviderContainer newContainer() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  test('padrão: vibrar e som ligados', () {
    final c = newContainer();
    expect(c.read(cookingAlertSettingsProvider), const CookingAlertSettings());
    expect(c.read(cookingAlertSettingsProvider).vibrate, isTrue);
    expect(c.read(cookingAlertSettingsProvider).sound, isTrue);
  });

  test('desligar fica salvo e volta igual na próxima abertura', () async {
    final first = newContainer();
    await first.read(cookingAlertSettingsProvider.notifier).setVibrate(false);
    await first.read(cookingAlertSettingsProvider.notifier).setSound(false);
    expect(first.read(cookingAlertSettingsProvider).vibrate, isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('cooking_alert_vibrate'), isFalse);
    expect(prefs.getBool('cooking_alert_sound'), isFalse);

    // "Reabre o app": container novo lê o que ficou no disco.
    final second = newContainer();
    second.read(cookingAlertSettingsProvider); // dispara a leitura
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(
      second.read(cookingAlertSettingsProvider),
      const CookingAlertSettings(vibrate: false, sound: false),
    );
  });

  test('cada chave é independente', () async {
    SharedPreferences.setMockInitialValues({'cooking_alert_sound': false});
    final c = newContainer();
    c.read(cookingAlertSettingsProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(
      c.read(cookingAlertSettingsProvider),
      const CookingAlertSettings(vibrate: true, sound: false),
    );
  });

  test('o alerta respeita as chaves: só vibra, só toca, os dois, nenhum',
      () async {
    final c = newContainer();
    final notifier = c.read(cookingAlertSettingsProvider.notifier);
    final alert = c.read(cookingAlertProvider);

    alert(); // padrão: os dois
    expect(platformCalls,
        containsAll(['HapticFeedback.vibrate', 'SystemSound.play']));

    platformCalls.clear();
    await notifier.setSound(false);
    alert();
    expect(platformCalls, ['HapticFeedback.vibrate']);

    platformCalls.clear();
    await notifier.setVibrate(false);
    await notifier.setSound(true);
    alert();
    expect(platformCalls, ['SystemSound.play']);

    platformCalls.clear();
    await notifier.setSound(false);
    alert();
    expect(platformCalls, isEmpty);
  });
}
