/// Custo estimado de receitas e do planejamento: preço que a pessoa informou
/// por ingrediente × quantidade da receita. Dart puro; só aritmética. O que não
/// dá pra calcular (sem preço, unidade sem conversão) fica fora da soma e é
/// apontado — o total é sempre "pelo menos isto".
library;

import 'package:receyta/data/database/seed_data.dart';
import 'package:receyta/domain/engine/unit_conversion.dart';
import 'package:receyta/domain/models/ingredient.dart';
import 'package:receyta/domain/models/recipe_ingredient.dart';

enum CostGap {
  /// O ingrediente não tem preço (ou a linha nem ligou a um ingrediente).
  noPrice,

  /// Tem preço, mas a unidade da receita não converte pra do preço (ex.:
  /// "2 dentes de alho" com preço por kg).
  cannotConvert,
}

/// O custo de uma linha de ingrediente. [cents] nulo = não deu pra calcular
/// ([gap] diz por quê); [counted] falso = a linha não entra na conta de
/// propósito ("a gosto", "pitada").
class LineCost {
  const LineCost({
    required this.line,
    this.cents,
    this.gap,
    this.counted = true,
  });

  final RecipeIngredient line;
  final int? cents;
  final CostGap? gap;
  final bool counted;

  String get name => line.ingredientName ?? line.rawText;
}

class RecipeCost {
  const RecipeCost(this.lines);

  final List<LineCost> lines;

  /// Soma do que deu pra calcular, em centavos.
  int get totalCents => lines.fold(0, (sum, l) => sum + (l.cents ?? 0));

  /// Linhas que entram na conta mas não foram calculadas.
  List<LineCost> get gaps => [
        for (final l in lines)
          if (l.counted && l.cents == null) l
      ];

  /// Quantas linhas entram na conta (fora "a gosto" e afins) e quantas
  /// delas já têm custo calculado.
  int get countedLines => lines.where((l) => l.counted).length;
  int get pricedLines => lines.where((l) => l.cents != null).length;

  /// Todo ingrediente da receita foi precificado (e há ao menos um).
  bool get complete => gaps.isEmpty && lines.any((l) => l.cents != null);

  /// Nenhuma linha foi calculada: não há o que mostrar.
  bool get isEmpty => !lines.any((l) => l.cents != null);

  /// Custo por porção, se a receita diz quantas rende.
  int? perServing(int? servings) => (servings == null || servings <= 0)
      ? null
      : (totalCents / servings).round();
}

final Map<String, SeedUnit> _unitByCode = {
  for (final u in kSeedUnits) u.code: u,
};

/// Custo da receita escrita em [lines]. [factor] escala as quantidades
/// (porções escolhidas). [catalog] liga o `ingredientId` da linha ao preço.
RecipeCost costOfRecipe(
  List<RecipeIngredient> lines,
  Map<String, Ingredient> catalog, {
  double factor = 1,
}) {
  return RecipeCost([
    for (final line in lines) _costOfLine(line, catalog, factor),
  ]);
}

LineCost _costOfLine(
  RecipeIngredient line,
  Map<String, Ingredient> catalog,
  double factor,
) {
  final unit = line.unitId == null ? null : _unitByCode[line.unitId];
  if (unit?.kind == 'subjective') {
    return LineCost(line: line, counted: false);
  }

  final ingredient =
      line.ingredientId == null ? null : catalog[line.ingredientId];
  final price = ingredient?.price;
  if (price == null) {
    return LineCost(line: line, gap: CostGap.noPrice);
  }
  final quantity = line.quantity;
  if (quantity == null || quantity <= 0) {
    return LineCost(line: line, gap: CostGap.cannotConvert);
  }

  final packs = _packsConsumed(
    quantity * factor,
    unit,
    price,
    ingredient!.displayName,
  );
  if (packs == null) {
    return LineCost(line: line, gap: CostGap.cannotConvert);
  }
  return LineCost(line: line, cents: (price.cents * packs).round());
}

/// Unidades em que dá pra informar um preço: tudo que não é "a gosto".
bool isPriceUnit(String code) {
  final unit = _unitByCode[code];
  return unit != null && unit.kind != 'subjective';
}

/// A unidade que já vem escolhida ao informar o preço de uma linha: a da
/// própria contagem ("dente", "maço"), "kg" pra peso, "l" pra volume e
/// "unidade" quando a linha não traz unidade ("3 ovos").
String suggestedPriceUnit(String? unitId) {
  final unit = unitId == null ? null : _unitByCode[unitId];
  if (unit == null) return 'unidade';
  return switch (unit.kind) {
    'mass' => 'kg',
    'volume' => 'l',
    'count' => unit.code,
    _ => 'unidade',
  };
}

/// Quantas vezes o preço informado ("R$ 4,50 por 500 g") cabe na quantidade
/// da linha, ou `null` quando as unidades não conversam.
double? _packsConsumed(
  double quantity,
  SeedUnit? lineUnit,
  IngredientPrice price,
  String ingredientName,
) {
  final priceUnit = _unitByCode[price.unitCode];
  if (priceUnit == null || price.quantity <= 0) return null;

  switch (priceUnit.kind) {
    case 'count':
      // Contagem só casa com a mesma contagem: "dente" com "dente",
      // "maço" com "maço"; sem unidade na linha ("3 ovos") vale "unidade".
      final same = lineUnit == null
          ? priceUnit.code == 'unidade'
          : lineUnit.code == priceUnit.code;
      return same ? quantity / price.quantity : null;

    case 'mass':
      final grams = _toGrams(quantity, lineUnit, ingredientName);
      if (grams == null) return null;
      return grams / (price.quantity * (priceUnit.factorToBase ?? 1));

    case 'volume':
      final ml = _toMl(quantity, lineUnit, ingredientName);
      if (ml == null) return null;
      return ml / (price.quantity * (priceUnit.factorToBase ?? 1));
  }
  return null;
}

double? _toGrams(double quantity, SeedUnit? unit, String name) {
  if (unit == null) return null;
  if (unit.kind == 'mass') return quantity * (unit.factorToBase ?? 1);
  if (unit.kind == 'volume') {
    final density = densityFor(name);
    if (density == null) return null;
    return quantity * (unit.factorToBase ?? 1) * density;
  }
  return null;
}

double? _toMl(double quantity, SeedUnit? unit, String name) {
  if (unit == null) return null;
  if (unit.kind == 'volume') return quantity * (unit.factorToBase ?? 1);
  if (unit.kind == 'mass') {
    final density = densityFor(name);
    if (density == null) return null;
    return quantity * (unit.factorToBase ?? 1) / density;
  }
  return null;
}

/// Uma receita do planejamento, pronta pra somar.
class PlannedRecipe {
  const PlannedRecipe({
    required this.recipeId,
    required this.name,
    required this.lines,
    this.factor = 1,
  });

  final String recipeId;
  final String name;
  final List<RecipeIngredient> lines;

  /// Porções planejadas ÷ porções da receita (1 = como escrita).
  final double factor;
}

class RecipeSpend {
  const RecipeSpend({
    required this.recipeId,
    required this.name,
    required this.cents,
    required this.times,
  });

  final String recipeId;
  final String name;
  final int cents;

  /// Quantas vezes ela aparece no período.
  final int times;
}

class IngredientSpend {
  const IngredientSpend({required this.name, required this.cents});

  final String name;
  final int cents;
}

class PlanCost {
  const PlanCost({
    required this.totalCents,
    required this.recipes,
    required this.ingredients,
    required this.missingNames,
  });

  final int totalCents;

  /// Da que mais pesou pra que menos pesou.
  final List<RecipeSpend> recipes;
  final List<IngredientSpend> ingredients;

  /// Ingredientes que ficaram fora da conta (sem preço ou sem conversão).
  final List<String> missingNames;

  bool get isEmpty => totalCents == 0;
}

/// Soma o custo de várias receitas (uma semana, um mês) e diz o que mais
/// pesou: por receita e por ingrediente.
PlanCost costOfPlan(
  Iterable<PlannedRecipe> planned,
  Map<String, Ingredient> catalog,
) {
  final byRecipe = <String, ({String name, int cents, int times})>{};
  final byIngredient = <String, int>{};
  final missing = <String>{};
  var total = 0;

  for (final p in planned) {
    final cost = costOfRecipe(p.lines, catalog, factor: p.factor);
    total += cost.totalCents;

    final prev = byRecipe[p.recipeId];
    byRecipe[p.recipeId] = (
      name: p.name,
      cents: (prev?.cents ?? 0) + cost.totalCents,
      times: (prev?.times ?? 0) + 1,
    );

    for (final l in cost.lines) {
      final cents = l.cents;
      if (cents != null) {
        byIngredient.update(l.name, (v) => v + cents, ifAbsent: () => cents);
      } else if (l.counted) {
        missing.add(l.name);
      }
    }
  }

  final recipes = [
    for (final e in byRecipe.entries)
      RecipeSpend(
        recipeId: e.key,
        name: e.value.name,
        cents: e.value.cents,
        times: e.value.times,
      ),
  ]..sort((a, b) => b.cents.compareTo(a.cents));
  final ingredients = [
    for (final e in byIngredient.entries)
      IngredientSpend(name: e.key, cents: e.value),
  ]..sort((a, b) => b.cents.compareTo(a.cents));

  return PlanCost(
    totalCents: total,
    recipes: recipes,
    ingredients: ingredients,
    missingNames: missing.toList()..sort(),
  );
}

/// "R$ 23,40".
String formatMoney(int cents) {
  final negative = cents < 0;
  final abs = cents.abs();
  final reais = abs ~/ 100;
  final centavos = (abs % 100).toString().padLeft(2, '0');
  final grouped = reais.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => '.',
      );
  return '${negative ? '-' : ''}R\$ $grouped,$centavos';
}

/// Lê "8,50", "8.50", "R$ 8,50" ou "1.250,90" em centavos. `null` se não for
/// um valor válido maior que zero.
int? parseMoneyToCents(String text) {
  var s = text.replaceAll(RegExp(r'[^0-9,.]'), '');
  if (s.isEmpty) return null;
  if (s.contains(',')) {
    s = s.replaceAll('.', '').replaceAll(',', '.');
  } else if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(s)) {
    s = s.replaceAll('.', '');
  }
  final value = double.tryParse(s);
  if (value == null || value <= 0) return null;
  return (value * 100).round();
}
