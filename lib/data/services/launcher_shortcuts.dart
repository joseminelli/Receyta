import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_actions/quick_actions.dart';

/// Atalhos que aparecem ao segurar o ícone do app.
enum LauncherShortcut {
  newRecipe('new_recipe', 'Nova receita', 'ic_shortcut_new_recipe'),
  shopping('shopping', 'Lista de compras', 'ic_shortcut_shopping'),
  cookLast('cook_last', 'Cozinhar a última', 'ic_shortcut_cook');

  const LauncherShortcut(this.type, this.title, this.icon);

  final String type;
  final String title;

  /// Nome do drawable em `android/app/src/main/res/drawable`.
  final String icon;

  static LauncherShortcut? fromType(String type) {
    for (final s in values) {
      if (s.type == type) return s;
    }
    return null;
  }
}

/// Registra os atalhos do launcher e avisa qual foi tocado. Sem plugin nativo
/// (teste de widget, plataforma sem suporte) falha em silêncio.
class LauncherShortcuts {
  LauncherShortcuts([QuickActions? plugin]) : _plugin = plugin ?? QuickActions();

  final QuickActions _plugin;

  Future<void> start(void Function(LauncherShortcut) onSelected) async {
    try {
      await _plugin.initialize((type) {
        final shortcut = LauncherShortcut.fromType(type);
        if (shortcut != null) onSelected(shortcut);
      });
      await _plugin.setShortcutItems([
        for (final s in LauncherShortcut.values)
          ShortcutItem(type: s.type, localizedTitle: s.title, icon: s.icon),
      ]);
    } catch (e) {
      debugPrint('LauncherShortcuts.start: $e');
    }
  }
}

final launcherShortcutsProvider = Provider<LauncherShortcuts>(
  (ref) => LauncherShortcuts(),
);
