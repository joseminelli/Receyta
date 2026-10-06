import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/core/day.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/domain/engine/text_normalize.dart';
import 'package:receyta/domain/engine/week_planner.dart';

/// Reúne do banco o que o motor de "Sugerir a semana" precisa: receitas
/// ativas, tags, histórico "cozinhei" e o que já está na agenda.
class WeekPlannerService {
  WeekPlannerService(this._db);

  final AppDatabase _db;

  Future<List<PlanCandidate>> candidates() async {
    final recipes = await (_db.select(_db.recipes)
          ..where((r) => r.deletedAt.isNull()))
        .get();

    final tagRows = await _db
        .customSelect(
          'SELECT rt.recipe_id AS rid, t.name AS name FROM recipe_tags rt '
          'JOIN tags t ON t.id = rt.tag_id',
        )
        .get();
    final tags = <String, Set<String>>{};
    for (final r in tagRows) {
      tags
          .putIfAbsent(r.read<String>('rid'), () => {})
          .add(stripAccents(r.read<String>('name').toLowerCase()));
    }

    final cookRows = await _db
        .customSelect(
          'SELECT recipe_id AS rid, MAX(cooked_at) AS last, COUNT(*) AS n '
          'FROM cook_logs GROUP BY recipe_id',
        )
        .get();
    final cooked = <String, ({DateTime last, int n})>{};
    for (final r in cookRows) {
      final last = DateTime.tryParse(r.read<String>('last'));
      if (last != null) {
        cooked[r.read<String>('rid')] = (last: last, n: r.read<int>('n'));
      }
    }

    final planRows = await _db
        .customSelect(
          'SELECT recipe_id AS rid, MAX(date) AS last FROM meal_plan_entries '
          'GROUP BY recipe_id',
        )
        .get();
    final scheduled = <String, DateTime>{};
    for (final r in planRows) {
      final d = DateTime.tryParse(r.read<String>('last'));
      if (d != null) scheduled[r.read<String>('rid')] = dayOf(d);
    }

    return [
      for (final r in recipes)
        PlanCandidate(
          id: r.id,
          name: r.name,
          tags: tags[r.id] ?? const {},
          totalMinutes: r.prepMinutes == null && r.cookMinutes == null
              ? null
              : (r.prepMinutes ?? 0) + (r.cookMinutes ?? 0),
          isFavorite: r.isFavorite,
          lastCookedAt: cooked[r.id]?.last,
          cookCount: cooked[r.id]?.n ?? 0,
          lastScheduledOn: scheduled[r.id],
        ),
    ];
  }
}

final weekPlannerServiceProvider = Provider<WeekPlannerService>(
  (ref) => WeekPlannerService(ref.watch(databaseProvider)),
);
