import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:receyta/core/day.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/domain/models/meal_plan_entry.dart';
import 'package:receyta/widgets/day_card_image.dart';

/// Compartilha o dia do calendário como imagem: desenha o cartão (ver
/// [renderDayCardPng]), grava um PNG temporário e abre o menu de
/// compartilhar do celular com ele já anexado.
class DayExportService {
  /// "receyta-dia-2026-10-02.png".
  static String fileName(DateTime day) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'receyta-dia-${day.year}-${two(day.month)}-${two(day.day)}.png';
  }

  /// Texto que acompanha a imagem.
  static String caption(DateTime day) =>
      'Meu dia no Receyta — ${day.day} de ${monthLong(day).toLowerCase()}';

  /// "receyta-semana-2026-09-28.png" (a data é a da segunda-feira).
  static String weekFileName(DateTime monday) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'receyta-semana-${monday.year}-${two(monday.month)}-${two(monday.day)}.png';
  }

  static String weekCaption(DateTime monday) =>
      'Minha semana no Receyta — ${weekRangeLabel(monday)}';

  /// Compartilha a semana que começa em [monday] (segunda) como imagem, com um
  /// dia por linha. [entries] pode trazer refeições de fora da semana: só as
  /// dela entram.
  Future<Result<void>> shareWeek(
    DateTime monday,
    List<MealPlanEntry> entries,
  ) async {
    final days = [
      for (var i = 0; i < 7; i++)
        WeekCardDay(
          day: addDays(monday, i),
          meals: [
            for (final e in _ordered(
              entries.where((e) => isSameDay(e.date, addDays(monday, i))),
            ))
              _toMeal(e),
          ],
        ),
    ];
    if (days.every((d) => d.meals.isEmpty)) {
      return const Err(ValidationFailure('Nada planejado pra compartilhar.'));
    }
    try {
      final png = await renderWeekCardPng(monday: monday, days: days);
      if (png == null) {
        return const Err(ProcessingFailure('Não deu pra gerar a imagem.'));
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${weekFileName(monday)}');
      await file.writeAsBytes(png, flush: true);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: weekCaption(monday),
      );
      return const Ok(null);
    } catch (e) {
      return Err(ProcessingFailure('Falha ao compartilhar a semana', cause: e));
    }
  }

  static List<MealPlanEntry> _ordered(Iterable<MealPlanEntry> entries) => [
        ...entries
      ]..sort((a, b) => a.mealType.index.compareTo(b.mealType.index));

  static DayCardMeal _toMeal(MealPlanEntry e) => DayCardMeal(
        recipeId: e.recipe.id,
        recipeName: e.recipe.name,
        mealLabel: e.mealType.label,
        tileColor: e.recipe.tileColor,
        tileMotif: e.recipe.tileMotif,
        done: e.done,
      );

  Future<Result<void>> shareDay(
    DateTime day,
    List<MealPlanEntry> entries,
  ) async {
    if (entries.isEmpty) {
      return const Err(ValidationFailure('Nada planejado pra compartilhar.'));
    }
    try {
      final png = await renderDayCardPng(
        day: day,
        meals: [
          for (final e in entries)
            DayCardMeal(
              recipeId: e.recipe.id,
              recipeName: e.recipe.name,
              mealLabel: e.mealType.label,
              tileColor: e.recipe.tileColor,
              tileMotif: e.recipe.tileMotif,
              done: e.done,
            ),
        ],
      );
      if (png == null) {
        return const Err(ProcessingFailure('Não deu pra gerar a imagem.'));
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${fileName(day)}');
      await file.writeAsBytes(png, flush: true);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: caption(day),
      );
      return const Ok(null);
    } catch (e) {
      return Err(ProcessingFailure('Falha ao compartilhar o dia', cause: e));
    }
  }
}

final dayExportServiceProvider = Provider<DayExportService>(
  (ref) => DayExportService(),
);
