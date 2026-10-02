import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receyta/data/services/reminder_notifications.dart';
import 'package:receyta/domain/engine/quiet_hours.dart';

const _kPlanWeek = 'reminder_plan_week';
const _kPlanWeekday = 'reminder_plan_week_weekday';
const _kPlanMinutes = 'reminder_plan_week_minutes';
const _kQuiet = 'reminder_quiet';
const _kQuietStart = 'reminder_quiet_start';
const _kQuietEnd = 'reminder_quiet_end';

/// Preferências dos lembretes (G5): um interruptor por tipo, quando o lembrete
/// semanal chega e o horário silencioso. Tudo desligado por padrão.
@immutable
class ReminderSettings {
  const ReminderSettings({
    this.planWeek = false,
    this.planWeekWeekday = DateTime.sunday,
    this.planWeekMinutes = 18 * 60,
    this.quiet = const QuietHours(),
  });

  final bool planWeek;
  final int planWeekWeekday;
  final int planWeekMinutes;
  final QuietHours quiet;

  /// Quando o lembrete semanal chega de fato, já empurrado pra fora do
  /// horário silencioso (que pode jogar pro dia seguinte).
  ({int weekday, int minutes}) get planWeekEffective {
    final shifted = quiet.shift(planWeekMinutes);
    final weekday = ((planWeekWeekday - 1 + shifted.dayOffset) % 7) + 1;
    return (weekday: weekday, minutes: shifted.minutes);
  }

  ReminderSettings copyWith({
    bool? planWeek,
    int? planWeekWeekday,
    int? planWeekMinutes,
    QuietHours? quiet,
  }) =>
      ReminderSettings(
        planWeek: planWeek ?? this.planWeek,
        planWeekWeekday: planWeekWeekday ?? this.planWeekWeekday,
        planWeekMinutes: planWeekMinutes ?? this.planWeekMinutes,
        quiet: quiet ?? this.quiet,
      );

  @override
  bool operator ==(Object other) =>
      other is ReminderSettings &&
      other.planWeek == planWeek &&
      other.planWeekWeekday == planWeekWeekday &&
      other.planWeekMinutes == planWeekMinutes &&
      other.quiet == quiet;

  @override
  int get hashCode =>
      Object.hash(planWeek, planWeekWeekday, planWeekMinutes, quiet);
}

Future<ReminderSettings> loadReminderSettings() async {
  try {
    final p = await SharedPreferences.getInstance();
    return ReminderSettings(
      planWeek: p.getBool(_kPlanWeek) ?? false,
      planWeekWeekday: p.getInt(_kPlanWeekday) ?? DateTime.sunday,
      planWeekMinutes: p.getInt(_kPlanMinutes) ?? 18 * 60,
      quiet: QuietHours(
        enabled: p.getBool(_kQuiet) ?? false,
        startMinutes: p.getInt(_kQuietStart) ?? 22 * 60,
        endMinutes: p.getInt(_kQuietEnd) ?? 8 * 60,
      ),
    );
  } catch (e) {
    debugPrint('loadReminderSettings: $e');
    return const ReminderSettings();
  }
}

class ReminderSettingsNotifier extends Notifier<ReminderSettings> {
  bool _touched = false;

  @override
  ReminderSettings build() {
    _load();
    return const ReminderSettings();
  }

  Future<void> _load() async {
    final loaded = await loadReminderSettings();
    if (!_touched) state = loaded;
  }

  /// Reagenda os lembretes ligados com o que está salvo. Chamada na abertura
  /// do app: refaz o agendamento (fuso novo, aparelho reiniciado) sem pedir
  /// permissão.
  Future<void> syncOnStart() async {
    final settings = _touched ? state : await loadReminderSettings();
    if (!_touched) state = settings;
    await _apply(settings);
  }

  /// Liga ou desliga o lembrete de planejar a semana. Ligar pela primeira vez
  /// pede a permissão de notificação; negada, o interruptor volta a desligado.
  Future<bool> setPlanWeek(bool on) async {
    _touched = true;
    if (on) {
      final granted =
          await ref.read(reminderNotificationsProvider).requestPermission();
      if (!granted) {
        state = state.copyWith(planWeek: false);
        await _persist();
        return false;
      }
    }
    state = state.copyWith(planWeek: on);
    await _persist();
    await _apply(state);
    return true;
  }

  Future<void> setPlanWeekWhen({int? weekday, int? minutes}) async {
    _touched = true;
    state = state.copyWith(planWeekWeekday: weekday, planWeekMinutes: minutes);
    await _persist();
    await _apply(state);
  }

  Future<void> setQuiet(QuietHours quiet) async {
    _touched = true;
    state = state.copyWith(quiet: quiet);
    await _persist();
    await _apply(state);
  }

  Future<void> _apply(ReminderSettings s) async {
    final service = ref.read(reminderNotificationsProvider);
    if (s.planWeek) {
      final when = s.planWeekEffective;
      await service.schedulePlanWeek(
        weekday: when.weekday,
        minutes: when.minutes,
      );
    } else {
      await service.cancelPlanWeek();
    }
  }

  Future<void> _persist() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kPlanWeek, state.planWeek);
      await p.setInt(_kPlanWeekday, state.planWeekWeekday);
      await p.setInt(_kPlanMinutes, state.planWeekMinutes);
      await p.setBool(_kQuiet, state.quiet.enabled);
      await p.setInt(_kQuietStart, state.quiet.startMinutes);
      await p.setInt(_kQuietEnd, state.quiet.endMinutes);
    } catch (e) {
      debugPrint('ReminderSettings._persist: $e');
    }
  }
}

final reminderSettingsProvider =
    NotifierProvider<ReminderSettingsNotifier, ReminderSettings>(
  ReminderSettingsNotifier.new,
);
