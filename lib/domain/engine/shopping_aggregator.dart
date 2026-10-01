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

/// Balde de agregação: linhas sem quantidade nunca somam com nada (uma por
/// combinação `unitId`); contagem sem unidade ("3 ovos") soma só com outra
/// contagem sem unidade; as demais agrupam pela unidade-base.
String _bucketKey(RecipeIngredient line) {
  if (line.quantity == null) return 'unquantified:${line.unitId}';
  if (line.unitId == null) return 'count';
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
  final first = bucket.first;
  final displayName = first.ingredientName ?? first.rawText;

  if (first.quantity == null) {
    return AggregatedIngredient(
      ingredientKey: ingredientKey,
      displayName: displayName,
      quantity: null,
      unitCode: first.unitId,
      sources: _mergeSourcesByRecipe(bucket, null),
    );
  }

  if (first.unitId == null) {
    return AggregatedIngredient(
      ingredientKey: ingredientKey,
      displayName: displayName,
      quantity: bucket.fold<double>(0, (sum, l) => sum + l.quantity!),
      unitCode: null,
      sources: _mergeSourcesByRecipe(bucket, null, unitless: true),
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
    sources: _mergeSourcesByRecipe(bucket, baseCode),
  );
}

/// Uma linha por receita: `ShoppingItemSources` tem chave composta
/// (item, receita) — se a MESMA receita contribuir com mais de uma linha
/// pro mesmo balde (achado testando: "farinha" duas vezes na mesma receita,
/// uma seção e depois pra polvilhar), inserir as duas quebraria essa chave
/// única. Funde na unidade-base quando dá pra somar; sem receita repetida
/// (o caso comum) mantém a unidade original de cada linha, sem conversão à
/// toa.
List<ShoppingSourceLine> _mergeSourcesByRecipe(
  List<RecipeIngredient> bucket,
  String? baseCode, {
  bool unitless = false,
}) {
  final byRecipe = <String, List<RecipeIngredient>>{};
  for (final line in bucket) {
    byRecipe.putIfAbsent(line.recipeId, () => []).add(line);
  }

  return [
    for (final entry in byRecipe.entries)
      if (entry.value.length == 1 || (baseCode == null && !unitless))
        (
          recipeId: entry.key,
          quantity: entry.value.last.quantity,
          unitId: entry.value.last.unitId,
        )
      else if (unitless)
        (
          recipeId: entry.key,
          quantity: entry.value.fold<double>(0, (sum, l) => sum + l.quantity!),
          unitId: null,
        )
      else
        (
          recipeId: entry.key,
          quantity: entry.value.fold<double>(
            0,
            (sum, l) => sum + l.quantity! * _factorToBase(l.unitId!),
          ),
          unitId: baseCode,
        ),
  ];
}

/// Soma duas quantidades de um mesmo ingrediente (item já na lista + o que
/// uma receita nova traz). `null` quando são incompatíveis (g vs unidade,
/// dente vs cabeça): quem chama mantém as duas em linhas separadas. Sem
/// quantidade só combina com outra igual (continua sem número); contagem sem
/// unidade ("3 ovos") só soma com outra contagem sem unidade.
({double? quantity, String? unitCode})? combineQuantities({
  required double? quantityA,
  required String? unitA,
  required double? quantityB,
  required String? unitB,
}) {
  if (quantityA == null || quantityB == null) {
    if (quantityA == null && quantityB == null && unitA == unitB) {
      return (quantity: null, unitCode: unitA);
    }
    return null;
  }
  if (unitA == null || unitB == null) {
    if (unitA == null && unitB == null) {
      return (quantity: quantityA + quantityB, unitCode: null);
    }
    return null;
  }
  final base = _baseUnitCode(unitA);
  if (base != _baseUnitCode(unitB)) return null;
  final total =
      quantityA * _factorToBase(unitA) + quantityB * _factorToBase(unitB);
  final (quantity, unitCode) = _pickDisplayUnit(base, total);
  return (quantity: quantity, unitCode: unitCode);
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
