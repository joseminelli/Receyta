import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/core/day.dart';
import 'package:receyta/data/repositories/meal_plan_repository.dart';
import 'package:receyta/data/repositories/shopping_list_repository.dart';
import 'package:receyta/domain/models/meal_plan_entry.dart';
import 'package:receyta/domain/models/shopping_list.dart';
import 'package:receyta/domain/models/shopping_list_item.dart';

/// Quantos itens pendentes vão pro widget de compras.
const kWidgetShoppingItems = 8;

/// Empurra pros widgets da tela inicial (Android) o que eles mostram: as
/// refeições dos próximos 7 dias (widget "Hoje") e a lista de compras em aberto
/// com os itens que faltam (widget "Compras"). O widget filtra "hoje" sozinho,
/// então a virada do dia não depende do app aberto.
abstract class HomeWidgetService {
  Future<void> push(Map<String, Object?> data);
}

class ChannelHomeWidgetService implements HomeWidgetService {
  static const _channel = MethodChannel('receyta/home_widget');

  @override
  Future<void> push(Map<String, Object?> data) async {
    try {
      await _channel.invokeMethod<void>('update', data);
    } on MissingPluginException {
      return;
    } on PlatformException catch (e) {
      debugPrint('HomeWidgetService.push: $e');
    }
  }
}

final homeWidgetServiceProvider =
    Provider<HomeWidgetService>((ref) => ChannelHomeWidgetService());

/// Monta o pacote que o widget lê. Puro, pra testar.
Map<String, Object?> buildWidgetPayload({
  required List<MealPlanEntry> entries,
  required List<ShoppingListSummary> lists,
  List<ShoppingListItem> items = const [],
}) {
  final meals = [
    for (final e in entries)
      {
        'date': dayToParam(e.date),
        'meal': e.mealType.label,
        'order': e.mealType.index,
        'name': e.recipeName,
        'done': e.done,
      },
  ]..sort((a, b) {
      final d = (a['date'] as String).compareTo(b['date'] as String);
      return d != 0 ? d : (a['order'] as int).compareTo(b['order'] as int);
    });

  final open = [
    for (final l in lists)
      if (l.total - l.checked > 0) l,
  ];
  final pending = open.fold<int>(0, (s, l) => s + l.total - l.checked);
  final first = open.isEmpty ? null : open.first;
  return {
    'meals': meals,
    'shoppingPending': pending,
    'shoppingList': first?.list.name ?? '',
    'shoppingLists': open.length,
    'shoppingTotal': first?.total ?? 0,
    'shoppingChecked': first?.checked ?? 0,
    'shoppingItems': [
      for (final i in items)
        if (!i.checked) i.displayName,
    ].take(kWidgetShoppingItems).toList(),
  };
}

/// Mantém o widget em dia: observa agenda e compras e reenvia quando mudam.
class HomeWidgetSync {
  HomeWidgetSync(this._ref);

  final Ref _ref;
  final _subs = <StreamSubscription<Object?>>[];

  void start() {
    dispose();
    final plan = _ref.read(mealPlanRepositoryProvider);
    final shopping = _ref.read(shoppingListRepositoryProvider);
    final from = today();
    List<MealPlanEntry> entries = const [];
    List<ShoppingListSummary> lists = const [];
    List<ShoppingListItem> items = const [];

    void push() => _ref.read(homeWidgetServiceProvider).push(
          buildWidgetPayload(entries: entries, lists: lists, items: items),
        );

    final a = plan.watchRange(from, addDays(from, 7)).listen((v) {
      entries = v;
      push();
    }, onError: (_) {});
    final b = shopping.watchSummaries().listen((v) async {
      lists = v;
      final open = v.where((l) => l.total - l.checked > 0);
      try {
        items = open.isEmpty
            ? const []
            : await shopping.itemsOf(open.first.list.id);
      } catch (e) {
        debugPrint('HomeWidgetSync.items: $e');
        items = const [];
      }
      push();
    }, onError: (_) {});
    _subs.addAll([a, b]);
  }

  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }
}

final homeWidgetSyncProvider = Provider<HomeWidgetSync>((ref) {
  return HomeWidgetSync(ref);
});
