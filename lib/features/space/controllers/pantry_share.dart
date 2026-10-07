import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/data/sync/shared_sync_engine.dart';
import 'package:receyta/features/account/controllers/auth_controller.dart';
import 'package:receyta/features/space/controllers/space_controller.dart';

/// A despensa é da casa? Ligado, o que a pessoa marca como "sempre tenho"
/// sobe pra casa (não pra conta) e o que os outros marcam chega aqui: a
/// despensa vira uma só, e ninguém compra o que já tem. Desligado, volta a
/// subir pra conta. A escolha vale por conta e some quando a pessoa sai da casa.
class PantryShareController extends AsyncNotifier<bool> {
  static const prefsPrefix = 'space_pantry_';

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
        ValidationFailure('Crie ou entre numa casa para dividir a despensa.'),
      );
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await ref.read(databaseProvider).ingredientDao.resetPantrySync();
      if (on) {
        await prefs.remove('${SharedSyncEngine.cursorPrefix}$space');
      }
      await prefs.setBool('$prefsPrefix${user.id}', on);
      state = AsyncData(on);
      return const Ok(null);
    } catch (e) {
      return Err(
          DatabaseFailure('Falha ao mudar a despensa da casa', cause: e));
    }
  }
}

final pantrySharedProvider = AsyncNotifierProvider<PantryShareController, bool>(
  PantryShareController.new,
);
