import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/features/space/controllers/share_flag.dart';
import 'package:receyta/features/space/controllers/space_controller.dart';

/// As listas novas já nascem compartilhadas com a casa? É a última escolha do
/// interruptor "Compartilhar com a casa" da folha de nova lista.
class NewListsShareController extends ShareFlagController {
  @override
  String get prefsPrefix => 'space_new_lists_';

  @override
  String get field => 'new_lists';

  @override
  String get noSpaceMessage => 'Crie ou entre numa casa para compartilhar listas.';

  @override
  String get failureMessage => 'Falha ao guardar a escolha';

  @override
  bool? serverValue(SharePrefs prefs) => prefs.newLists;
}

final newListsSharedProvider =
    AsyncNotifierProvider<NewListsShareController, bool>(
  NewListsShareController.new,
);
