import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/bootstrap.dart';
import 'package:receyta/features/recipes/recipe_detail_page.dart';
import 'package:receyta/features/recipes/recipe_form_page.dart';
import 'package:receyta/home_shell.dart';
import 'package:receyta/root_back_guard.dart';
import 'package:receyta/splash.dart';

final router = GoRouter(
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
      builder: (context, state) => const RecipeFormPage(),
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
