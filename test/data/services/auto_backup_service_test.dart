import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/services/auto_backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory dir;
  late DateTime now;
  var recipes = 2;

  AutoBackupService service() => AutoBackupService(
        buildPayload: () async => Ok({
          'recipes': [
            for (var i = 0; i < recipes; i++) {'name': 'r$i'}
          ],
        }),
        directory: () async => dir,
        clock: () => now,
        keep: 3,
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('receyta_backup_test');
    now = DateTime(2026, 10, 2, 9, 30);
    recipes = 2;
  });

  tearDown(() => dir.delete(recursive: true));

  test('grava uma cópia na primeira abertura', () async {
    final result = await service().runIfDue();

    final file = (result as Ok<AutoBackupFile?>).value!;
    expect(file.path, endsWith('receyta-auto-20261002-0930.receyta'));
    expect(await File(file.path).readAsString(), contains('"recipes"'));
  });

  test('não repete antes de 20 horas, repete depois', () async {
    final s = service();
    await s.runIfDue();

    now = now.add(const Duration(hours: 5));
    expect((await s.runIfDue() as Ok<AutoBackupFile?>).value, isNull);
    expect(await s.list(), hasLength(1));

    now = now.add(const Duration(hours: 20));
    expect((await s.runIfDue() as Ok<AutoBackupFile?>).value, isNotNull);
    expect(await s.list(), hasLength(2));
  });

  test('desligado não faz nada', () async {
    final s = service();
    await s.setEnabled(false);

    expect((await s.runIfDue() as Ok<AutoBackupFile?>).value, isNull);
    expect(await s.list(), isEmpty);
  });

  test('guarda só as mais recentes', () async {
    final s = service();
    for (var i = 0; i < 5; i++) {
      now = now.add(const Duration(days: 1));
      await s.backupNow();
    }

    final copies = await s.list();
    expect(copies, hasLength(3));
    expect(copies.first.createdAt.day, 7);
    expect(copies.last.createdAt.day, 5);
  });

  test('biblioteca vazia não gera cópia', () async {
    recipes = 0;
    final result = await service().backupNow();

    expect((result as Ok<AutoBackupFile?>).value, isNull);
    expect(await service().list(), isEmpty);
  });
}
