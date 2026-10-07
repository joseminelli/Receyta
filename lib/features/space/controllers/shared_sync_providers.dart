import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/data/sync/shared_meal_sync.dart';
import 'package:receyta/data/sync/shared_remote.dart';
import 'package:receyta/data/sync/shared_sync_engine.dart';
import 'package:receyta/data/sync/sync_handlers.dart';
import 'package:receyta/features/account/controllers/auth_controller.dart';
import 'package:receyta/features/space/controllers/calendar_share.dart';
import 'package:receyta/features/space/controllers/pantry_share.dart';
import 'package:receyta/features/space/controllers/space_controller.dart';

/// O motor de uma casa. Uma instância por casa: o id mora no motor.
final sharedSyncEngineProvider =
    Provider.family<SharedSyncEngine, String>((ref, spaceId) {
  final db = ref.watch(databaseProvider);
  final recipes = ref.watch(recipeRepositoryProvider);
  final user = ref.watch(authUserProvider).valueOrNull;
  final calendarOn = ref.watch(calendarSharedProvider).valueOrNull ?? false;
  final pantryOn = ref.watch(pantrySharedProvider).valueOrNull ?? false;
  return SharedSyncEngine(
    remote: ref.watch(sharedRemoteProvider),
    db: db,
    spaceId: spaceId,
    handlers: sharedSyncHandlers(
      db,
      spaceId,
      myId: user?.id,
      pantry: pantryOn,
      meals: user == null || !calendarOn
          ? null
          : SharedMealSync(
              db,
              spaceId: spaceId,
              myId: user.id,
              myName: () async =>
                  ref.read(spaceControllerProvider.notifier).displayName(),
              snapshotOf: (id) => mealRecipeSnapshot(db, recipes, id),
            ),
    ),
  );
});
