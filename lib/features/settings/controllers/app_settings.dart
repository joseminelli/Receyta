import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receyta/core/tile_style.dart';

const _kTextSize = 'settings_text_size';
const _kHighContrast = 'settings_high_contrast';
const _kLastBackup = 'settings_last_backup_ms';
const _kNickname = 'profile_nickname';
const _kProfileColor = 'profile_color';

/// Tamanho do texto do app (RF-08.2): multiplicador próprio, que se soma à
/// escala de fonte do sistema em vez de depender dela.
enum TextSizeStep {
  normal(1.0, 'Normal'),
  large(1.15, 'Grande'),
  larger(1.3, 'Maior'),
  huge(1.5, 'Enorme');

  const TextSizeStep(this.factor, this.label);

  final double factor;
  final String label;
}

TextSizeStep _textSizeFromName(String? name) {
  for (final s in TextSizeStep.values) {
    if (s.name == name) return s;
  }
  return TextSizeStep.normal;
}

/// Preferências do app: tamanho do texto, alto contraste (RF-08.3), quando
/// foi o último backup (pro aviso de "Limpar dados", RF-08.4) e o perfil
/// local (apelido e cor do avatar) da aba Conta.
@immutable
class AppSettings {
  const AppSettings({
    this.textSize = TextSizeStep.normal,
    this.highContrast = false,
    this.lastBackupAt,
    this.nickname = '',
    this.profileColor = TileColor.coral,
  });

  final TextSizeStep textSize;
  final bool highContrast;
  final DateTime? lastBackupAt;

  /// Como a pessoa quer ser chamada; vazio = ainda não escolheu.
  final String nickname;
  final TileColor profileColor;

  AppSettings copyWith({
    TextSizeStep? textSize,
    bool? highContrast,
    DateTime? lastBackupAt,
    String? nickname,
    TileColor? profileColor,
  }) =>
      AppSettings(
        textSize: textSize ?? this.textSize,
        highContrast: highContrast ?? this.highContrast,
        lastBackupAt: lastBackupAt ?? this.lastBackupAt,
        nickname: nickname ?? this.nickname,
        profileColor: profileColor ?? this.profileColor,
      );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.textSize == textSize &&
      other.highContrast == highContrast &&
      other.lastBackupAt == lastBackupAt &&
      other.nickname == nickname &&
      other.profileColor == profileColor;

  @override
  int get hashCode => Object.hash(
        textSize,
        highContrast,
        lastBackupAt,
        nickname,
        profileColor,
      );
}

/// Lê do disco antes de o app abrir, pra tela já nascer no tamanho e no tema
/// certos (sem piscar do padrão pro escolhido). Falha = padrão.
Future<AppSettings> loadAppSettings() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final backupMs = prefs.getInt(_kLastBackup);
    return AppSettings(
      textSize: _textSizeFromName(prefs.getString(_kTextSize)),
      highContrast: prefs.getBool(_kHighContrast) ?? false,
      lastBackupAt: backupMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(backupMs),
      nickname: prefs.getString(_kNickname) ?? '',
      profileColor:
          tileColorFromName(prefs.getString(_kProfileColor)) ?? TileColor.coral,
    );
  } catch (e) {
    debugPrint('loadAppSettings: $e');
    return const AppSettings();
  }
}

/// O que `main` leu do disco; os testes deixam o padrão.
final initialAppSettingsProvider =
    Provider<AppSettings>((ref) => const AppSettings());

class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(initialAppSettingsProvider);

  Future<void> setTextSize(TextSizeStep step) async {
    state = state.copyWith(textSize: step);
    await _write((p) => p.setString(_kTextSize, step.name));
  }

  Future<void> setHighContrast(bool on) async {
    state = state.copyWith(highContrast: on);
    await _write((p) => p.setBool(_kHighContrast, on));
  }

  Future<void> markBackedUp(DateTime at) async {
    state = state.copyWith(lastBackupAt: at);
    await _write((p) => p.setInt(_kLastBackup, at.millisecondsSinceEpoch));
  }

  Future<void> setProfile({
    required String nickname,
    required TileColor color,
  }) async {
    final name = nickname.trim();
    state = state.copyWith(nickname: name, profileColor: color);
    await _write((p) async {
      await p.setString(_kNickname, name);
      return p.setString(_kProfileColor, color.name);
    });
  }

  Future<void> _write(Future<bool> Function(SharedPreferences) op) async {
    try {
      await op(await SharedPreferences.getInstance());
    } catch (e) {
      debugPrint('AppSettings._write: $e');
    }
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettings>(AppSettingsNotifier.new);
