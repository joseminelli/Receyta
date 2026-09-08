import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'root_back_guard.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const RootBackGuard(child: HomePage()),
    ),
    GoRoute(
      path: '/recipes',
      name: 'recipes',
      builder: (context, state) => const RecipesPage(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Página não encontrada: ${state.uri}'),
    ),
  ),
);

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receyta'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Bem-vindo ao Receyta!'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.push('/recipes'),
              child: const Text('Ir para Receitas'),
            ),
          ],
        ),
      ),
    );
  }
}

class RecipesPage extends StatelessWidget {
  const RecipesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receitas'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Página de Receitas'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }
}
