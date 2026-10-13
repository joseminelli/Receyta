import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kCostOpen = 'shopping_cost_open';
const _kItemPrices = 'shopping_item_prices';

/// Como a página de uma lista mostra os valores: o cartão do total (recolhido
/// por padrão) e o preço de cada item. Valem para todas as listas.
@immutable
class ShoppingViewPrefs {
  const ShoppingViewPrefs({this.costOpen = false, this.itemPrices = true});

  final bool costOpen;
  final bool itemPrices;

  ShoppingViewPrefs copyWith({bool? costOpen, bool? itemPrices}) =>
      ShoppingViewPrefs(
        costOpen: costOpen ?? this.costOpen,
        itemPrices: itemPrices ?? this.itemPrices,
      );
}

class ShoppingViewPrefsNotifier extends Notifier<ShoppingViewPrefs> {
  bool _disposed = false;

  @override
  ShoppingViewPrefs build() {
    ref.onDispose(() => _disposed = true);
    _load();
    return const ShoppingViewPrefs();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_disposed) return;
      state = ShoppingViewPrefs(
        costOpen: prefs.getBool(_kCostOpen) ?? false,
        itemPrices: prefs.getBool(_kItemPrices) ?? true,
      );
    } catch (e) {
      debugPrint('ShoppingViewPrefs.load: $e');
    }
  }

  Future<void> setCostOpen(bool open) async {
    state = state.copyWith(costOpen: open);
    await _write(_kCostOpen, open);
  }

  Future<void> setItemPrices(bool show) async {
    state = state.copyWith(itemPrices: show);
    await _write(_kItemPrices, show);
  }

  Future<void> _write(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('ShoppingViewPrefs.write: $e');
    }
  }
}

final shoppingViewPrefsProvider =
    NotifierProvider<ShoppingViewPrefsNotifier, ShoppingViewPrefs>(
  ShoppingViewPrefsNotifier.new,
);
