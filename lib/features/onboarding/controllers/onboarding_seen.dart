import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'onboarding_seen_v1';

/// A introdução de primeiro uso já foi vista? Em qualquer falha de leitura
/// responde "sim": errar pro lado de não mostrar é melhor que travar a
/// abertura do app numa tela que o usuário já viu.
Future<bool> loadOnboardingSeen() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  } catch (e) {
    debugPrint('loadOnboardingSeen: $e');
    return true;
  }
}

Future<void> markOnboardingSeen() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  } catch (e) {
    debugPrint('markOnboardingSeen: $e');
  }
}
