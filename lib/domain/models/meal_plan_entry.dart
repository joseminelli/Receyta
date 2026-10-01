import 'package:freezed_annotation/freezed_annotation.dart';

part 'meal_plan_entry.freezed.dart';

/// Refeição do dia (RF-04.2). `code` é o que vai pro banco
/// (`meal_plan_entries.meal_type`).
enum MealType {
  breakfast('cafe', 'Café da manhã'),
  lunch('almoco', 'Almoço'),
  dinner('jantar', 'Jantar'),
  snack('lanche', 'Lanche');

  const MealType(this.code, this.label);

  final String code;
  final String label;

  /// Texto desconhecido (dado de versão futura, edição manual) cai em
  /// almoço em vez de quebrar a tela.
  static MealType fromCode(String code) => MealType.values.firstWhere(
        (m) => m.code == code,
        orElse: () => MealType.lunch,
      );
}

/// Uma receita agendada num dia e refeição (RF-04.2). `date` é a data de
/// calendário (ver `core/day.dart`).
@freezed
class MealPlanEntry with _$MealPlanEntry {
  const factory MealPlanEntry({
    required String id,
    required String recipeId,
    required String recipeName,
    required DateTime date,
    required MealType mealType,
    int? servingsOverride,
    String? note,
    @Default(false) bool done,
  }) = _MealPlanEntry;
}
