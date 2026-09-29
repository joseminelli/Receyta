import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/bootstrap.dart';
import 'package:receyta/domain/engine/recipe_import.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/features/folders/screens/all_folders_page.dart';
import 'package:receyta/features/folders/screens/folder_page.dart';
import 'package:receyta/features/recipes/screens/cooking_mode_page.dart';
import 'package:receyta/features/recipes/screens/ingredients_page.dart';
import 'package:receyta/features/recipes/screens/recipe_detail_page.dart';
import 'package:receyta/features/recipes/screens/recipe_form_page.dart';
import 'package:receyta/features/recipes/screens/search_page.dart';
import 'package:receyta/features/recipes/screens/tags_page.dart';
import 'package:receyta/features/recipes/screens/trash_page.dart';
import 'package:receyta/features/settings/screens/settings_page.dart';
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
      // Sem transição de página padrão (fade+slide do Material colidia com
      // o voo do Hero do azulejo, e o bloco parecia "sumir"). O Hero em si
      // fica de fora do paint normal enquanto voa (o Flutter cuida disso
      // sozinho), então dar um fade+leve subida só ao RESTO do conteúdo —
      // sincronizado com a mesma janela do voo — deixa tudo parecendo uma
      // coisa só, em vez do bloco animar liso e o resto cortar seco.
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 500),
        child: RecipeDetailPage(
          recipeId: state.pathParameters['id']!,
          initialRecipe: state.extra as Recipe?,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Content termina de entrar/começa a sair um pouco antes do fim
          // do voo, pra nunca parecer que ainda tá "chegando" depois do
          // bloco já ter assentado.
          final fade = CurvedAnimation(
            parent: animation,
            curve: const Interval(0, 0.65, curve: Curves.easeOut),
            reverseCurve: const Interval(0.35, 1, curve: Curves.easeIn),
          );
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(fade),
              child: child,
            ),
          );
        },
      ),
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
