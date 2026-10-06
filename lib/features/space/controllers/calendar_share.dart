import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receyta/core/day.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/data/sync/shared_sync_engine.dart';
import 'package:receyta/features/account/controllers/auth_controller.dart';
import 'package:receyta/features/space/controllers/space_controller.dart';

/// A pessoa participa do calendário da casa? Ligado, as refeições dela daqui
/// pra frente sobem pra casa e as dos outros aparecem no calendário dela.
/// Desligado, o calendário é só dela. A escolha vale por conta e some quando a
/// pessoa sai da casa.
class CalendarShareController extends AsyncNotifier<bool> {
  static const prefsPrefix = 'space_calendar_';

  @override
  Future<bool> build() async {
    final user = ref.watch(authUserProvider).valueOrNull;
    final space = ref.watch(currentSpaceIdProvider);
    if (user == null || space == null) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$prefsPrefix${user.id}') ?? false;
  }

  Future<Result<void>> set(bool on) async {
    final user = ref.read(authUserProvider).valueOrNull;
    final space = ref.read(currentSpaceIdProvider);
    if (user == null || space == null) {
      return const Err(
        ValidationFailure('Crie ou entre numa casa para dividir o calendário.'),
      );
    }
    try {
      final dao = ref.read(databaseProvider).mealPlanDao;
      final prefs = await SharedPreferences.getInstance();
      if (on) {
        await dao.shareFrom(space, today());
        await prefs.remove('${SharedSyncEngine.cursorPrefix}$space');
      } else {
        await dao.unshare(space);
      }
      await prefs.setBool('$prefsPrefix${user.id}', on);
      state = AsyncData(on);
      return const Ok(null);
    } catch (e) {
      return Err(
          DatabaseFailure('Falha ao mudar o calendário da casa', cause: e));
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
