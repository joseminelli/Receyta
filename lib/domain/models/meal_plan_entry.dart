import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:receyta/domain/models/recipe.dart';

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
/// calendário (ver `core/day.dart`). Carrega a [recipe] inteira: o card da
/// semana usa a cor/textura dela e abrir o detalhe já sai com ela pronta.
@freezed
class MealPlanEntry with _$MealPlanEntry {
  const MealPlanEntry._();

  const factory MealPlanEntry({
    required String id,
    required Recipe recipe,
    required DateTime date,
    required MealType mealType,
    int? servingsOverride,
    String? note,
    @Default(false) bool done,

    /// Casa em que a refeição é compartilhada (nulo = só da pessoa).
    String? spaceId,

    /// Nome de quem planejou, quando foi OUTRA pessoa da casa; nulo nas
    /// refeições da própria pessoa. Refeição de outra pessoa carrega só um
    /// resumo da receita (não existe na biblioteca daqui).
    String? sharedBy,
  }) = _MealPlanEntry;

  bool get isFromOther => sharedBy != null;

  String get recipeId => recipe.id;
  String get recipeName => recipe.name;
}
