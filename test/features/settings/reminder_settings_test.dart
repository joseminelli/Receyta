import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/data/services/reminder_notifications.dart';
import 'package:receyta/domain/engine/quiet_hours.dart';
import 'package:receyta/features/settings/controllers/reminder_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeReminders implements ReminderNotifications {
  _FakeReminders({this.grant = true});

  final bool grant;
  final calls = <String>[];

  @override
  Future<bool> requestPermission() async {
    calls.add('permission');
    return grant;
  }

  @override
  Future<void> schedulePlanWeek({
    required int weekday,
    required int minutes,
  }) async =>
      calls.add('schedule:$weekday:$minutes');

  @override
  Future<void> cancelPlanWeek() async => calls.add('cancel');
}

void main() {
  late _FakeReminders fake;
  late ProviderContainer container;

  ReminderSettingsNotifier notifier() =>
      container.read(reminderSettingsProvider.notifier);
  ReminderSettings settings() => container.read(reminderSettingsProvider);

  void build({bool grant = true}) {
    SharedPreferences.setMockInitialValues({});
    fake = _FakeReminders(grant: grant);
    container = ProviderContainer(
      overrides: [reminderNotificationsProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);
    container.read(reminderSettingsProvider);
  }

  test('começa tudo desligado, domingo às 18:00', () {
    build();

    expect(settings().planWeek, isFalse);
    expect(settings().planWeekWeekday, DateTime.sunday);
    expect(settings().planWeekMinutes, 18 * 60);
    expect(settings().quiet.enabled, isFalse);
  });

  test('ligar pede a permissão e agenda o lembrete', () async {
    build();

    final ok = await notifier().setPlanWeek(true);

    expect(ok, isTrue);
    expect(settings().planWeek, isTrue);
    expect(fake.calls, ['permission', 'schedule:7:${18 * 60}']);
  });

  test('permissão negada: o interruptor volta desligado e nada é agendado',
      () async {
    build(grant: false);

    final ok = await notifier().setPlanWeek(true);

    expect(ok, isFalse);
    expect(settings().planWeek, isFalse);
    expect(fake.calls, ['permission']);
  });

  test('desligar cancela o agendamento', () async {
    build();
    await notifier().setPlanWeek(true);
    fake.calls.clear();

    await notifier().setPlanWeek(false);

    expect(fake.calls, ['cancel']);
  });

  test('mudar dia e hora reagenda', () async {
    build();
    await notifier().setPlanWeek(true);
    fake.calls.clear();

    await notifier().setPlanWeekWhen(weekday: DateTime.friday, minutes: 9 * 60);

    expect(fake.calls, ['schedule:5:${9 * 60}']);
  });

  test('horário silencioso empurra o lembrete pro fim da faixa', () async {
    build();
    await notifier().setPlanWeek(true);
    await notifier().setPlanWeekWhen(minutes: 23 * 60);
    fake.calls.clear();

    await notifier().setQuiet(const QuietHours(enabled: true));

    // Domingo 23:00 cai em 22:00–08:00: vai pra segunda às 08:00.
    expect(settings().planWeekEffective, (weekday: 1, minutes: 8 * 60));
    expect(fake.calls, ['schedule:1:${8 * 60}']);
  });

  test('fora do horário silencioso o lembrete fica onde está', () async {
    build();
    await notifier().setPlanWeek(true);
    fake.calls.clear();

    await notifier().setQuiet(const QuietHours(enabled: true));

    expect(settings().planWeekEffective, (weekday: 7, minutes: 18 * 60));
    expect(fake.calls, ['schedule:7:${18 * 60}']);
  });

  test('as preferências voltam do disco', () async {
    build();
    await notifier().setPlanWeek(true);
    await notifier().setPlanWeekWhen(weekday: DateTime.friday, minutes: 540);
    await notifier().setQuiet(
      const QuietHours(enabled: true, startMinutes: 1300, endMinutes: 400),
    );

    final loaded = await loadReminderSettings();

    expect(loaded.planWeek, isTrue);
    expect(loaded.planWeekWeekday, DateTime.friday);
    expect(loaded.planWeekMinutes, 540);
    expect(loaded.quiet.startMinutes, 1300);
    expect(loaded.quiet.endMinutes, 400);
  });

  test('na abertura reagenda o que está ligado, sem pedir permissão', () async {
    build();
    await notifier().setPlanWeek(true);
    fake.calls.clear();

    await notifier().syncOnStart();

    expect(fake.calls, ['schedule:7:${18 * 60}']);
  });

  test('na abertura, com tudo desligado, só garante que não há agendamento',
      () async {
    build();

    await notifier().syncOnStart();

    expect(fake.calls, ['cancel']);
  });
}
