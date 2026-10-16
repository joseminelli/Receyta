import 'package:flutter/material.dart';

import 'package:receyta/domain/engine/ingredient_category.dart';
import 'package:receyta/domain/models/ingredient.dart';

/// Ícone do corredor do mercado (slug de `kSeedCategories`): o mesmo da lista
/// de compras e dos ingredientes.
IconData categoryIcon(String slug) => switch (slug) {
      'hortifruti' => Icons.eco_outlined,
      'acougue' => Icons.kebab_dining_outlined,
      'peixaria' => Icons.set_meal_outlined,
      'frios_laticinios' => Icons.egg_alt_outlined,
      'padaria' => Icons.bakery_dining_outlined,
      'mercearia' => Icons.shopping_basket_outlined,
      'massas_molhos' => Icons.ramen_dining_outlined,
      'enlatados_conservas' => Icons.inventory_2_outlined,
      'temperos_condimentos' => Icons.spa_outlined,
      'matinais_cereais' => Icons.breakfast_dining_outlined,
      'congelados' => Icons.ac_unit,
      'bebidas' => Icons.local_drink_outlined,
      'doces_sobremesas' => Icons.cake_outlined,
      'higiene_limpeza' => Icons.cleaning_services_outlined,
      _ => Icons.category_outlined,
    };

/// Ícone do tipo do [ingredient]: a categoria gravada no catálogo, ou a que o
/// nome sugere quando não há.
IconData ingredientIcon(Ingredient ingredient) => categoryIcon(
      categorySlugFromId(ingredient.categoryId) ??
          categorySlugFor(ingredient.displayName),
    );

/// Bolinha escura com o ícone do tipo do ingrediente em lima.
class IngredientIconBadge extends StatelessWidget {
  const IngredientIconBadge({
    super.key,
    required this.ingredient,
    this.size = 44,
    required this.ink,
    required this.accent,
  });

  final Ingredient ingredient;
  final double size;
  final Color ink;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
      child: Icon(ingredientIcon(ingredient), size: size * 0.5, color: accent),
    );
  }
}
