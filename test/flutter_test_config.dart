import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:sqlite3/open.dart';

/// `flutter test` não carrega plugins nativos, então o `sqlite3` que o app usa
/// via `sqlite3_flutter_libs` não existe aqui. Este hook aponta o loader para
/// uma biblioteca sqlite3 disponível na máquina de teste / no CI:
///
/// - **Windows:** `winsqlite3.dll` (vem com o Windows 10/11; SQLite recente,
///   com FTS5). Fallback para `sqlite3.dll` no PATH.
/// - **Linux (CI):** `libsqlite3.so` do sistema (`apt-get install libsqlite3-0`).
/// - **macOS:** a `libsqlite3.dylib` do sistema já resolve sem override.
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
