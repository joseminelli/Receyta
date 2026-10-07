import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/data/sync/shared_sync_engine.dart';
import 'package:receyta/features/space/controllers/share_flag.dart';
import 'package:receyta/features/space/controllers/space_controller.dart';

/// A despensa é da casa? Ligado, o que a pessoa marca como "sempre tenho"
/// sobe pra casa (não pra conta) e o que os outros marcam chega aqui: a
/// despensa vira uma só, e ninguém compra o que já tem. Desligado, volta a
/// subir pra conta.
class PantryShareController extends ShareFlagController {
  @override
  String get prefsPrefix => 'space_pantry_';

  @override
  String get field => 'pantry';

  @override
  String get noSpaceMessage => 'Crie ou entre numa casa para dividir a despensa.';

  @override
  String get failureMessage => 'Falha ao mudar a despensa da casa';

  @override
  bool? serverValue(SharePrefs prefs) => prefs.pantry;

  @override
  Future<void> apply(bool on, String spaceId) async {
    await ref.read(databaseProvider).ingredientDao.resetPantrySync();
    if (on) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${SharedSyncEngine.cursorPrefix}$spaceId');
    }
  }
}

final pantrySharedProvider = AsyncNotifierProvider<PantryShareController, bool>(
  PantryShareController.new,
);
