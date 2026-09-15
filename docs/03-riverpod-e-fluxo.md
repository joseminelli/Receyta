# Riverpod, navegação e o fluxo ponta a ponta

> Parte 3 de 7 do guia técnico. [Índice](../arquitetura-e-fluxo.md) ·
> anterior: [O banco local](02-banco-local.md).

## Riverpod: os quatro tipos de `Provider` que aparecem no código

Riverpod é injeção de dependência + gerenciamento de estado no mesmo
mecanismo. Um `Provider` é uma "receita" de como construir um valor; ele só é
de fato construído na primeira vez que alguém o lê, e fica em cache até
alguém pedir para descartar.

- **`Provider<T>`** — valor construído uma vez, não reativo. Uso típico: expor
  um objeto (banco, repositório, ViewModel).
  ```dart
  final databaseProvider = Provider<AppDatabase>((ref) {
    final db = AppDatabase();
    ref.onDispose(db.close);   // fecha o arquivo .sqlite quando o app derruba o ProviderScope
    return db;
  });
  ```
  ([`data/database/database_provider.dart`](../lib/data/database/database_provider.dart))

- **`StreamProvider<T>`** — reconstrói automaticamente toda vez que a stream
  emite. É o mecanismo por trás de "a lista de receitas atualiza sozinha
  quando eu salvo uma nova, sem chamar `setState`":
  ```dart
  final recipesStreamProvider = StreamProvider<List<Recipe>>((ref) {
    final tagIds = ref.watch(selectedTagIdsProvider);
    ...
    return ref.watch(recipesViewModelProvider).watchRecipes(tagIds: tagIds, ...);
  });
  ```
  ([`features/recipes/recipes_view_model.dart:58`](../lib/features/recipes/recipes_view_model.dart))
  Repare que esse provider **depende de outro provider** (`selectedTagIdsProvider`)
  via `ref.watch`. Se o filtro de tag mudar, o Riverpod desmonta a stream
  antiga, assina a nova query no Drift automaticamente, e a UI recebe a nova
  lista — sem nenhum código explícito de "refazer a busca". (Trilhado em
  detalhe, com o widget real, em
  [Exemplos reais na View §1](04-exemplos-na-view.md#1-filtro-por-tagfavoritos-na-home--providers-encadeados).)

- **`StateProvider<T>`** — uma "caixinha" de estado mutável simples (um filtro,
  um texto de busca). Ex.: `selectedTagIdsProvider`, `searchQueryProvider`.
  A UI muda com `ref.read(x.notifier).state = novoValor`.

- **`FutureProvider<T>`** — como `StreamProvider`, mas para uma operação
  assíncrona que roda uma vez. `appBootstrapProvider`
  ([`bootstrap.dart`](../lib/bootstrap.dart)) é o exemplo mais importante: a
  splash (`lib/router.dart`, rota `/splash`) faz
  `ref.watch(appBootstrapProvider.future)` e só navega para `/` quando o banco
  terminou de abrir, migrar e limpar a lixeira vencida.

`ProviderScope` em `main.dart` é a raiz que guarda todo esse cache — é
essencialmente o "container de DI" da árvore de widgets inteira.

---

## Navegação: `go_router`

Rotas são declaradas uma vez em [`router.dart`](../lib/router.dart), por
**path** (`/recipe/:id`), não por push imperativo de `Widget`:

```dart
GoRoute(path: '/recipe/:id', name: 'recipe-detail',
    builder: (context, state) => RecipeDetailPage(recipeId: state.pathParameters['id']!)),
```

Navegar é `context.go('/recipe/$id')` ou `context.push(...)`. A vantagem sobre
`Navigator.push` direto: cada tela tem uma URL real, o que é pré-requisito
para "abrir um arquivo compartilhado por outro app" (bloco D do plano) e para
deep link em geral — a URL já existe, só falta o handler de intent.

`RootBackGuard` (em torno da `HomeShell` na rota `/`) intercepta o botão
"voltar" do Android na tela raiz para não fechar o app sem confirmação/estado
esperado — é UI, não roteamento em si.

---

## Trilhando um fluxo completo: salvar uma receita

Para fixar como as camadas conversam, aqui está o caminho real de "usuário
aperta salvar no formulário" até "a lista da home atualiza sozinha":

1. **View** — `RecipeFormPage` chama algo como
   `ref.read(recipeFormViewModelProvider.notifier).save()`.
2. **ViewModel** (`RecipeFormViewModel`) já tem o estado do formulário (nome,
   linhas de ingrediente digitadas, etc.) e chama
   `recipeRepository.saveDetail(name: ..., ingredientLines: [...], ...)`.
3. **Repository** (`RecipeRepository.saveDetail`,
   [`data/repositories/recipe_repository.dart:95`](../lib/data/repositories/recipe_repository.dart)):
   - monta um `Recipe` novo (`Uuid().v4()`, timestamps UTC) ou copia o
     existente (`base.copyWith(...)`) se for edição;
   - transforma cada linha de texto em um `RecipeIngredientRow`/`RecipeStepRow`
     com `position` sequencial e `groupLabel`;
   - resolve as tags digitadas para IDs via `TagDao.ensureTags` (getOrCreate
     por nome);
   - chama `_dao.saveWithChildren(...)` — e só aí toca em Drift de fato;
   - devolve `Ok(recipe)` ou `Err(DatabaseFailure(...))` (ver
     [Result/Failure](02-banco-local.md#resultfailure-por-que-não-trycatch-na-ui)).
4. **DAO** (`RecipeDao.saveWithChildren`,
   [`data/database/daos/recipe_dao.dart:114`](../lib/data/database/daos/recipe_dao.dart)):
   roda tudo dentro de **uma transação** — insere/atualiza a linha de
   `recipes`, apaga todas as linhas antigas de ingredientes/passos/tags dessa
   receita e insere as novas em lote (`batch`). É reposição total, não diff:
   mais simples de raciocinar, e o volume de linhas por receita é pequeno o
   bastante para não importar.
5. **SQLite** grava no arquivo `receyta.sqlite`. Qualquer `Stream` que dependia
   da tabela `recipes` (ex.: `watchActive()`) detecta a mudança e emite de
   novo.
6. Essa nova emissão sobe por `RecipeRepository.watchAll` →
   `RecipesViewModel.watchRecipes` → `recipesStreamProvider` (Riverpod) — e
   qualquer `ConsumerWidget` que faz `ref.watch(recipesStreamProvider)`
   reconstrói sozinho, sem a `RecipeFormPage` saber que isso aconteceu.

O ponto-chave: **a View da home nunca pergunta "a lista mudou?"** — ela está
inscrita numa stream, e a escrita em outro lugar do app propaga sozinha. É
essa reatividade de ponta a ponta (SQLite → Drift stream → Riverpod →
widget) que substitui o que em outras arquiteturas seria feito com
`EventBus`, `setState` manual entre telas, ou callbacks de refresh.

---

**Próximo:** [Exemplos reais na View](04-exemplos-na-view.md) — cinco fluxos
reais, trilhados a partir do widget que aparece na tela.
