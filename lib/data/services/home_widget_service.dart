import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/core/day.dart';
import 'package:receyta/data/repositories/meal_plan_repository.dart';
import 'package:receyta/data/repositories/shopping_list_repository.dart';
import 'package:receyta/domain/models/meal_plan_entry.dart';
import 'package:receyta/domain/models/shopping_list.dart';

/// Empurra pro widget da tela inicial (Android) o que ele mostra: as refeições
/// dos próximos 7 dias e o resumo das compras em aberto. O widget filtra "hoje"
/// sozinho, então a virada do dia não depende do app aberto.
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
  return {
    'meals': meals,
    'shoppingPending': pending,
    'shoppingList': open.isEmpty ? '' : open.first.list.name,
    'shoppingLists': open.length,
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

    void push() => _ref.read(homeWidgetServiceProvider).push(
          buildWidgetPayload(entries: entries, lists: lists),
        );

    final a = plan.watchRange(from, addDays(from, 7)).listen((v) {
      entries = v;
      push();
    }, onError: (_) {});
    final b = shopping.watchSummaries().listen((v) {
      lists = v;
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
