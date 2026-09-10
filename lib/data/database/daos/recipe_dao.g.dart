// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_dao.dart';

// ignore_for_file: type=lint
mixin _$RecipeDaoMixin on DatabaseAccessor<AppDatabase> {
  $FoldersTable get folders => attachedDatabase.folders;
  $RecipesTable get recipes => attachedDatabase.recipes;
  $CategoriesTable get categories => attachedDatabase.categories;
  $IngredientsTable get ingredients => attachedDatabase.ingredients;
  $UnitsTable get units => attachedDatabase.units;
  $RecipeIngredientsTable get recipeIngredients =>
      attachedDatabase.recipeIngredients;
  $RecipeStepsTable get recipeSteps => attachedDatabase.recipeSteps;
  $TagsTable get tags => attachedDatabase.tags;
  $RecipeTagsTable get recipeTags => attachedDatabase.recipeTags;
}
