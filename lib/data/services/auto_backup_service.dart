import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/services/recipe_export_service.dart';

const _kEnabled = 'auto_backup_enabled';
const _kLastMs = 'auto_backup_last_ms';

/// Uma cópia automática guardada no aparelho.
@immutable
class AutoBackupFile {
  const AutoBackupFile({
    required this.path,
    required this.createdAt,
    required this.bytes,
  });

  final String path;
  final DateTime createdAt;
  final int bytes;
}

/// Backup automático (sem conta e sem servidor): no máximo uma vez por dia,
/// ao abrir o app, grava o mesmo `.receyta` do backup manual numa pasta
/// própria e mantém só as [keep] mais recentes. Protege de apagar receita ou
/// limpar os dados por engano; a cópia do Android (Google) leva a pasta junto
/// pra um aparelho novo. Biblioteca vazia nunca gera cópia (não pisa nas boas).
class AutoBackupService {
  AutoBackupService({
    required this.buildPayload,
    Future<Directory> Function()? directory,
    DateTime Function()? clock,
    this.keep = 7,
    this.minGap = const Duration(hours: 20),
  })  : _directory = directory ?? _defaultDirectory,
        _clock = clock ?? DateTime.now;

  final Future<Result<Map<String, dynamic>>> Function() buildPayload;
  final Future<Directory> Function() _directory;
  final DateTime Function() _clock;
  final int keep;
  final Duration minGap;

  static Future<Directory> _defaultDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'backups'));
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kEnabled) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, value);
  }

  Future<DateTime?> lastRunAt() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_kLastMs);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Faz a cópia se estiver ligado e já passou [minGap] da última. Nunca lança.
  Future<Result<AutoBackupFile?>> runIfDue() async {
    try {
      if (!await isEnabled()) return const Ok(null);
      final last = await lastRunAt();
      if (last != null && _clock().difference(last) < minGap) {
        return const Ok(null);
      }
      return backupNow();
    } catch (e) {
      debugPrint('AutoBackupService.runIfDue: $e');
      return Err(ProcessingFailure('Falha no backup automático', cause: e));
    }
  }

  /// Grava uma cópia agora. `Ok(null)` quando não há receita pra guardar.
  Future<Result<AutoBackupFile?>> backupNow() async {
    try {
      final payloadResult = await buildPayload();
      if (payloadResult is Err<Map<String, dynamic>>) {
        return Err(payloadResult.failure);
      }
      final payload = (payloadResult as Ok<Map<String, dynamic>>).value;
      if ((payload['recipes'] as List?)?.isEmpty ?? true) {
        return const Ok(null);
      }

      final dir = await _directory();
      await dir.create(recursive: true);
      final now = _clock();
      final file = File(p.join(dir.path, _fileName(now)));
      await file.writeAsString(jsonEncode(payload), flush: true);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kLastMs, now.millisecondsSinceEpoch);
      await _prune();
      return Ok(AutoBackupFile(
        path: file.path,
        createdAt: now,
        bytes: await file.length(),
      ));
    } catch (e) {
      debugPrint('AutoBackupService.backupNow: $e');
      return Err(ProcessingFailure('Falha ao gravar o backup', cause: e));
    }
  }

  /// Cópias guardadas, da mais nova pra mais antiga.
  Future<List<AutoBackupFile>> list() async {
    try {
      final dir = await _directory();
      if (!await dir.exists()) return const [];
      final files = <AutoBackupFile>[];
      await for (final e in dir.list()) {
        if (e is! File || !e.path.endsWith('.receyta')) continue;
        final stat = await e.stat();
        files.add(AutoBackupFile(
          path: e.path,
          createdAt: _parseDate(p.basename(e.path)) ?? stat.modified,
          bytes: stat.size,
        ));
      }
      files.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return files;
    } catch (e) {
      debugPrint('AutoBackupService.list: $e');
      return const [];
    }
  }

  Future<void> delete(AutoBackupFile file) async {
    try {
      await File(file.path).delete();
    } catch (e) {
      debugPrint('AutoBackupService.delete: $e');
    }
  }

  Future<void> _prune() async {
    final all = await list();
    for (final old in all.skip(keep)) {
      await delete(old);
    }
  }

  /// `receyta-auto-20261002-1430.receyta` (hora local).
  static String _fileName(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'receyta-auto-${t.year}${two(t.month)}${two(t.day)}-'
        '${two(t.hour)}${two(t.minute)}.receyta';
  }

  static DateTime? _parseDate(String name) {
    final m = RegExp(r'receyta-auto-(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})')
        .firstMatch(name);
    if (m == null) return null;
    final v = [for (var i = 1; i <= 5; i++) int.parse(m.group(i)!)];
    return DateTime(v[0], v[1], v[2], v[3], v[4]);
  }
}

final autoBackupServiceProvider = Provider<AutoBackupService>((ref) {
  final export = ref.watch(recipeExportServiceProvider);
  return AutoBackupService(buildPayload: export.buildFullBackupPayload);
});

class AutoBackupState {
  const AutoBackupState({this.enabled = true, this.lastAt, this.count = 0});

  final bool enabled;
  final DateTime? lastAt;
  final int count;
}

class AutoBackupController extends AsyncNotifier<AutoBackupState> {
  AutoBackupService get _service => ref.read(autoBackupServiceProvider);

  @override
  Future<AutoBackupState> build() => _load();

  Future<AutoBackupState> _load() async => AutoBackupState(
        enabled: await _service.isEnabled(),
        lastAt: await _service.lastRunAt(),
        count: (await _service.list()).length,
      );

  /// Chamado ao abrir o app.
  Future<void> runIfDue() async {
    await _service.runIfDue();
    state = AsyncData(await _load());
  }

  Future<void> setEnabled(bool value) async {
    await _service.setEnabled(value);
    if (value) await _service.runIfDue();
    state = AsyncData(await _load());
  }

  Future<Result<AutoBackupFile?>> backupNow() async {
    final result = await _service.backupNow();
    state = AsyncData(await _load());
    return result;
  }

  Future<void> delete(AutoBackupFile file) async {
    await _service.delete(file);
    state = AsyncData(await _load());
  }
}

final autoBackupProvider =
    AsyncNotifierProvider<AutoBackupController, AutoBackupState>(
  AutoBackupController.new,
);
