import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Abre `receyta.sqlite` no diretório de documentos do app. `LazyDatabase` adia
/// a abertura até a primeira query — o que a splash aguarda via
/// `AppDatabase.ensureReady()`. Só plataformas nativas; na web o alvo é a
/// galeria, que não toca no banco.
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'receyta.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
