import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:sqlite3/open.dart';

/// `flutter test` roda na Dart VM sem plugins nativos, então a sqlite3 que o
/// app usa via `sqlite3_flutter_libs` não existe aqui. Este hook aponta o
/// loader para uma lib do sistema: `winsqlite3.dll` no Windows, `libsqlite3` no
/// Linux (o CI instala `libsqlite3-0`), e a do sistema no macOS.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (Platform.isWindows) {
    open.overrideForAll(_openWindows);
  } else if (Platform.isLinux) {
    open.overrideForAll(() => DynamicLibrary.open('libsqlite3.so.0'));
  }
  await testMain();
}

DynamicLibrary _openWindows() {
  for (final name in const ['winsqlite3.dll', 'sqlite3.dll']) {
    try {
      return DynamicLibrary.open(name);
    } on ArgumentError {
      continue;
    }
  }
  throw StateError('Nenhuma sqlite3 encontrada para os testes (Windows).');
}
