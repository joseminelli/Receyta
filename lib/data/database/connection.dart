import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Abre o arquivo do banco em disco (`receyta.sqlite` no diretório de
/// documentos do app). `LazyDatabase` adia a abertura até a primeira query —
/// é o que a splash aguarda via `AppDatabase.ensureReady()`.
///
/// Só cobre plataformas nativas (Android/iOS/desktop). Na web o alvo é a
/// galeria de componentes, que não toca no banco; um `driftDatabase` com WASM
/// entra se e quando o app rodar na web.
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'receyta.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
