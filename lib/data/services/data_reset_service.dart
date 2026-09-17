import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/database/database_provider.dart';

/// "Limpar dados" (RF-08.4) — apaga tudo do banco local. A confirmação dupla
/// e o aviso pra exportar antes ficam na UI (`AccountPage`); este serviço só
/// executa depois que o usuário já confirmou.
class DataResetService {
  DataResetService(this._db);

  final AppDatabase _db;

  Future<Result<void>> wipeAll() async {
    try {
      await _db.wipeUserData();
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseFailure('Falha ao limpar os dados', cause: e));
    }
  }
}

final dataResetServiceProvider = Provider<DataResetService>((ref) {
  return DataResetService(ref.watch(databaseProvider));
});
