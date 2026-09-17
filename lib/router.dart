import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/bootstrap.dart';
import 'package:receyta/domain/engine/recipe_import.dart';
import 'package:receyta/features/folders/all_folders_page.dart';
import 'package:receyta/features/folders/folder_page.dart';
import 'package:receyta/features/recipes/cooking_mode_page.dart';
import 'package:receyta/features/recipes/ingredients_page.dart';
import 'package:receyta/features/recipes/recipe_detail_page.dart';
import 'package:receyta/features/recipes/recipe_form_page.dart';
import 'package:receyta/features/recipes/search_page.dart';
import 'package:receyta/features/recipes/tags_page.dart';
import 'package:receyta/features/recipes/trash_page.dart';
import 'package:receyta/features/settings/settings_page.dart';
import 'package:receyta/home_shell.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/root_back_guard.dart';
import 'package:receyta/splash.dart';

final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const _SplashRoute(),
    ),
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const RootBackGuard(child: HomeShell()),
    ),
    GoRoute(
      path: '/recipe/new',
      name: 'recipe-new',
      builder: (context, state) =>
          RecipeFormPage(draft: state.extra as ImportedRecipe?),
    ),
    GoRoute(
      path: '/recipe/:id',
      name: 'recipe-detail',
      builder: (context, state) =>
          RecipeDetailPage(recipeId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/recipe/:id/edit',
      name: 'recipe-edit',
      builder: (context, state) =>
          RecipeFormPage(recipeId: state.pathParameters['id']),
    ),
    GoRoute(
      path: '/recipe/:id/cook',
      name: 'recipe-cook',
      builder: (context, state) =>
          CookingModePage(recipeId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/folder/:id',
      name: 'folder',
      builder: (context, state) =>
          FolderPage(folderId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/folders',
      name: 'folders',
      builder: (context, state) => const AllFoldersPage(),
    ),
    GoRoute(
      path: '/trash',
      name: 'trash',
      builder: (context, state) => const TrashPage(),
    ),
    GoRoute(
      path: '/tags',
      name: 'tags',
      builder: (context, state) => const TagsPage(),
    ),
    GoRoute(
      path: '/ingredients',
      name: 'ingredients',
      builder: (context, state) => const IngredientsPage(),
    ),
    GoRoute(
      path: '/search',
      name: 'search',
      builder: (context, state) => const SearchPage(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Página não encontrada: ${state.uri}')),
  ),
);

/// Liga a splash à inicialização real do app e navega para a home ao fim.
class _SplashRoute extends ConsumerWidget {
  const _SplashRoute();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Splash(
      ready: ref.watch(appBootstrapProvider.future),
      onComplete: () => context.go('/'),
    );
  }
}
