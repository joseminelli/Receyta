import 'package:receyta/data/database/seed_data.dart';
import 'package:receyta/domain/models/recipe_ingredient.dart';

/// Uma origem de um item agregado: quanto ESSA receita contribuiu, na
/// unidade original dela (não convertida) — é o que `ShoppingItemSources`
/// grava (RF-05.8, "de quais receitas veio").
typedef ShoppingSourceLine = ({
  String recipeId,
  double? quantity,
  String? unitId,
});

/// Linha pronta pra lista de compras (E2 monta a partir disto): quantidade
/// total numa unidade só, quando deu pra somar, e de quais receitas veio.
class AggregatedIngredient {
  const AggregatedIngredient({
    required this.ingredientKey,
    required this.displayName,
    required this.quantity,
    required this.unitCode,
    required this.sources,
  });

  /// `ingredientId` do catálogo, ou uma chave sintética a partir do
  /// `rawText` pra linha nunca resolvida (sem catálogo pra casar com outra
  /// receita, mas ainda entra na lista).
  final String ingredientKey;
  final String displayName;

  /// Nulo quando nenhuma origem tinha quantidade numérica reconhecida — a
  /// tela mostra a unidade/texto cru sem número, não inventa um.
  final double? quantity;
  final String? unitCode;
  final List<ShoppingSourceLine> sources;
}

/// Agrega linhas de ingrediente de várias receitas selecionadas: o mesmo
/// ingrediente com unidades da mesma família convertível (g/kg/mg entre si,
/// ml/l/xícara/colher entre si) soma num total só; famílias incompatíveis
/// (g vs unidade, dente vs cabeça) ficam em linhas separadas — nunca inventa
/// uma conversão que a [kSeedUnits] não define. Dart puro, sem banco.
List<AggregatedIngredient> aggregateIngredients(
  List<RecipeIngredient> lines,
) {
  final byIngredient = <String, List<RecipeIngredient>>{};
  for (final line in lines) {
    final key = line.ingredientId ?? 'raw:${line.rawText.trim().toLowerCase()}';
    byIngredient.putIfAbsent(key, () => []).add(line);
  }

  final out = <AggregatedIngredient>[];
  for (final entry in byIngredient.entries) {
    final buckets = <String, List<RecipeIngredient>>{};
    for (final line in entry.value) {
      buckets.putIfAbsent(_bucketKey(line), () => []).add(line);
    }
    for (final bucket in buckets.values) {
      out.add(_mergeBucket(entry.key, bucket));
    }
  }
  return out;
}

/// Balde de agregação: linhas sem quantidade/unidade nunca somam com nada
/// (uma por combinação `unitId`), as demais agrupam pela unidade-base.
String _bucketKey(RecipeIngredient line) {
  if (line.quantity == null || line.unitId == null) {
    return 'unquantified:${line.unitId}';
  }
  return _baseUnitCode(line.unitId!);
}

/// Unidade-base pra fins de agregação: se a unidade converte pra outra
/// (`baseUnitCode`), é essa; senão ela mesma é a base (`g`, `ml`, `unidade`,
/// `dente`...) — cada unidade de contagem/subjetiva é sua própria base,
/// nunca cruza com outra unidade de contagem.
String _baseUnitCode(String unitCode) {
  for (final u in kSeedUnits) {
    if (u.code == unitCode) return u.baseUnitCode ?? u.code;
  }
  return unitCode;
}

double _factorToBase(String unitCode) {
  for (final u in kSeedUnits) {
    if (u.code == unitCode) return u.factorToBase ?? 1;
  }
  return 1;
}

AggregatedIngredient _mergeBucket(
  String ingredientKey,
  List<RecipeIngredient> bucket,
) {
  final sources = [
    for (final b in bucket)
      (recipeId: b.recipeId, quantity: b.quantity, unitId: b.unitId),
  ];
  final first = bucket.first;
  final displayName = first.ingredientName ?? first.rawText;

  if (first.quantity == null || first.unitId == null) {
    return AggregatedIngredient(
      ingredientKey: ingredientKey,
      displayName: displayName,
      quantity: null,
      unitCode: first.unitId,
      sources: sources,
    );
  }

  final baseCode = _baseUnitCode(first.unitId!);
  var totalInBase = 0.0;
  for (final line in bucket) {
    totalInBase += line.quantity! * _factorToBase(line.unitId!);
  }

  final (quantity, unitCode) = _pickDisplayUnit(baseCode, totalInBase);
  return AggregatedIngredient(
    ingredientKey: ingredientKey,
    displayName: displayName,
    quantity: quantity,
    unitCode: unitCode,
    sources: sources,
  );
}

/// Sobe pra `kg`/`l` acima de 1000 na base de massa/volume (500g + 800g vira
/// 1,3kg). Fora mass/volume (contagem, subjetivo) exibe na própria
/// unidade-base — não tem "quilo de dente de alho".
(double, String) _pickDisplayUnit(String baseCode, double totalInBase) {
  if (baseCode == 'g' && totalInBase >= 1000) {
    return (totalInBase / 1000, 'kg');
  }
  if (baseCode == 'ml' && totalInBase >= 1000) {
    return (totalInBase / 1000, 'l');
  }
  return (totalInBase, baseCode);
}
