import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receyta/core/day.dart';
import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/data/sync/shared_sync_engine.dart';
import 'package:receyta/features/space/controllers/share_flag.dart';
import 'package:receyta/features/space/controllers/space_controller.dart';

/// A pessoa participa do calendário da casa? Ligado, as refeições dela daqui
/// pra frente sobem pra casa e as dos outros aparecem no calendário dela.
/// Desligado, o calendário é só dela.
class CalendarShareController extends ShareFlagController {
  @override
  String get prefsPrefix => 'space_calendar_';

  @override
  String get field => 'calendar';

  @override
  String get noSpaceMessage =>
      'Crie ou entre numa casa para dividir o calendário.';

  @override
  String get failureMessage => 'Falha ao mudar o calendário da casa';

  @override
  bool? serverValue(SharePrefs prefs) => prefs.calendar;

  @override
  Future<void> apply(bool on, String spaceId) async {
    final dao = ref.read(databaseProvider).mealPlanDao;
    if (on) {
      await dao.shareFrom(spaceId, today());
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${SharedSyncEngine.cursorPrefix}$spaceId');
    } else {
      await dao.unshare(spaceId);
    }
  }
}

final calendarSharedProvider =
    AsyncNotifierProvider<CalendarShareController, bool>(
  CalendarShareController.new,
);

/// A casa onde as refeições novas nascem: só quando a pessoa participa do
/// calendário da casa. Nulo = o calendário é só dela.
final calendarSpaceIdProvider = Provider<String?>((ref) {
  final on = ref.watch(calendarSharedProvider).valueOrNull ?? false;
  return on ? ref.watch(currentSpaceIdProvider) : null;
});
