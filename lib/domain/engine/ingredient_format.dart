/// Formatação de ingrediente pra texto corrido (§8.1) — extraído da tela de
/// detalhe pra ser reaproveitado pelo PDF (D6) sem duplicar a lógica de
/// unidade por extenso.
library;

import 'package:receyta/data/database/seed_data.dart';
import 'package:receyta/domain/engine/ingredient_parser.dart';
import 'package:receyta/domain/models/recipe_ingredient.dart';

/// Unidade por extenso (singular/plural) a partir do código salvo — nunca
/// abreviada (ex. "colheres de sopa", não "2cs").
String? unitDisplayLabel(String? unitCode, double quantity) {
  if (unitCode == null) return null;
  for (final u in kSeedUnits) {
    if (u.code == unitCode) return quantity == 1 ? u.displayName : u.plural;
  }
  return null;
}

/// Linha de ingrediente pronta pra texto corrido: "1,5 xícara de chá de
/// Farinha de trigo, peneirada". Sem quantidade reconhecida, cai pro
/// `rawText` cru — nunca esconde o que o usuário digitou.
String formatIngredientLine(RecipeIngredient ingredient) {
  final qty = ingredient.quantity;
  if (qty == null) return ingredient.rawText;

  final parsed = parseIngredientLine(ingredient.rawText);
  final unit = unitDisplayLabel(ingredient.unitId, qty);
  final name = ingredient.ingredientName ?? parsed.name;

  final buffer = StringBuffer(_formatQuantity(qty));
  if (unit != null) buffer.write(' $unit de');
  buffer.write(' $name');
  if (parsed.qualifier != null) buffer.write(', ${parsed.qualifier}');
  return buffer.toString();
}

String _formatQuantity(double q) {
  var s = q.toStringAsFixed(2);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '');
    s = s.replaceFirst(RegExp(r'\.$'), '');
  }
  return s.replaceAll('.', ',');
}
