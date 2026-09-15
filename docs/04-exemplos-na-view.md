# Exemplos reais na View

> Parte 4 de 7 do guia técnico. [Índice](../arquitetura-e-fluxo.md) ·
> anterior: [Riverpod e o fluxo](03-riverpod-e-fluxo.md).

O arquivo anterior trilhou "salvar uma receita" partindo do ViewModel. Este
faz o inverso: parte do `Widget` de verdade — o que aparece na tela — e mostra
a linha exata que liga toque → provider → repositório → banco. É a parte que
mais ajuda a "destravar" quando você está lendo uma tela pela primeira vez.

## 1. Filtro por tag/favoritos na home — providers encadeados

Em [`features/recipes/recipes_page.dart:282-297`](../lib/features/recipes/recipes_page.dart),
o header lê três providers e escreve em dois deles ao tocar num chip:

```dart
final selected = ref.watch(selectedTagIdsProvider);          // StateProvider<Set<String>>
final favoritesOnly = ref.watch(favoritesOnlyProvider);       // StateProvider<bool>

void setSelected(Set<String> next) =>
    ref.read(selectedTagIdsProvider.notifier).state = next;   // grava, não assiste
```

Tocar num `_HeaderChip` de tag chama `setSelected(next)`. Isso muda o valor de
`selectedTagIdsProvider` — e é só isso que o widget faz diretamente. O resto é
reação em cadeia, definida em
[`features/recipes/recipes_view_model.dart:58-69`](../lib/features/recipes/recipes_view_model.dart):

```dart
final recipesStreamProvider = StreamProvider<List<Recipe>>((ref) {
  final tagIds = ref.watch(selectedTagIdsProvider);         // 1. reage à mudança
  final favoritesOnly = ref.watch(favoritesOnlyProvider);
  final rootOnly = tagIds.isEmpty && !favoritesOnly;         // 2. decide o modo
  return ref.watch(recipesViewModelProvider).watchRecipes(   // 3. reassina a query no Drift
        tagIds: tagIds, favoritesOnly: favoritesOnly, rootOnly: rootOnly,
      );
});
```

Cadeia completa: **toque no chip → `selectedTagIdsProvider` muda → Riverpod
invalida `recipesStreamProvider` porque ele fez `ref.watch` daquele provider →
uma nova stream é assinada no `RecipeDao.watchActive(anyOfTagIds: ...)` →
`RecipesPage.build` (que fez `ref.watch(recipesStreamProvider)` na linha 45)
reconstrói com a lista filtrada.** Nenhum `setState`, nenhum callback manual —
o widget nem sabe que existe um filtro de tag rolando por baixo, só que a
lista mudou.

Repare também no detalhe de `rootOnly` (comentário em
`recipes_view_model.dart:61`): sem filtro nenhum, a home mostra só a raiz
(pastas escondem as receitas de dentro); ao ligar qualquer filtro, a busca
passa a valer pra base inteira, inclusive dentro de pastas — é uma regra de
produto, não uma coincidência técnica.

## 2. Busca com debounce — separar "o que aparece no campo" de "o que dispara query"

[`features/recipes/search_page.dart:42-56`](../lib/features/recipes/search_page.dart)
usa **dois** estados para o texto de busca, de propósito:

```dart
void _onChanged(String value) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 250), () {
    if (mounted) ref.read(searchQueryProvider.notifier).state = value;
  });
}
```

- `_controller` (um `TextEditingController` comum) reflete cada tecla
  digitada, instantaneamente — é estado 100% local da View, nunca precisa
  passar por Riverpod.
- `searchQueryProvider` (Riverpod) só é atualizado 250ms depois da última
  tecla. Isso existe porque `searchQueryProvider` dispara uma query FTS5 real
  no SQLite (via `searchResultsProvider` → `RecipeRepository.search` →
  `RecipeDao.search`, ver [busca por texto](02-banco-local.md#busca-por-texto-fts5))
  — sem o debounce, cada tecla digitada rápido geraria uma consulta ao banco
  desperdiçada.

Isso ilustra uma regra geral: **nem todo estado de tela precisa ser
Riverpod.** Estado que não tem por que ser observado por outra parte do app
(texto de um campo, posição de scroll) fica em `State` local do
`ConsumerStatefulWidget`; só o que alimenta uma query ou é compartilhado entre
telas vira `Provider`.

## 3. Lixeira — duas ações, dois métodos de Repository, sem `Result` na tela

[`features/recipes/trash_page.dart:110-119`](../lib/features/recipes/trash_page.dart):

```dart
final repo = ref.read(recipeRepositoryProvider);   // read, não watch: é uma ação, não uma leitura reativa
...
IconButton(onPressed: () => repo.restore(r.id), ...),
IconButton(onPressed: () => repo.deleteForever(r.id), ...),
```

Repare que aqui a tela **ignora** o `Result` que `restore`/`deleteForever`
devolvem — não trata `err`. É uma escolha aceitável porque essas operações
praticamente não falham em uso normal (é update por `id` já existente na
tela) e uma falha nelas não deixa o usuário travado. Compare com o exemplo 4
abaixo, que trata os dois lados porque mover pra pasta *pode* falhar por
regra de negócio (ciclo). A régua não é "sempre trate o `Err`", é "trate
quando o `Err` for algo que o usuário precisa saber para agir diferente".

A lista em si (`trashed = ref.watch(trashedRecipesProvider)`) é a mesma
mecânica de stream de sempre — `RecipeDao.watchTrashed()` filtra
`deletedAt.isNotNull()` (ver [soft delete e lixeira](02-banco-local.md#soft-delete-e-lixeira))
e atualiza sozinha quando `restore` ou `deleteForever` mexem na tabela.

## 4. Arrastar receita para pasta — `Result` tratado nos dois lados

O drag-and-drop (`features/folders/recipe_drag.dart`) é `Draggable` +
`DragTarget` do Flutter puro por baixo, mas o ponto interessante é o que
acontece ao soltar, em
[`recipe_drag.dart:287-298`](../lib/features/folders/recipe_drag.dart):

```dart
onAcceptWithDetails: (details) async {
  final repo = ref.read(folderRepositoryProvider);
  final result = switch (details.data) {
    RecipeDragItem(:final id) => await repo.moveRecipe(id, folderId),
    FolderDragItem(:final id) => await repo.move(id, folderId),
  };
  result.when(
    ok: (_) => showRootSnackBar(SnackBar(content: Text('Movida para "$folderName"'))),
    err: (f) => showRootSnackBar(SnackBar(content: Text(f.message))),
  );
},
```

`switch` sobre um `sealed class DragItem` (`RecipeDragItem` vs.
`FolderDragItem`, definidos no topo do mesmo arquivo) decide qual método do
`FolderRepository` chamar — o padrão exaustivo do Dart garante, em tempo de
compilação, que um terceiro tipo de item arrastável nunca fica esquecido
aqui. `FolderRepository.move`
([`data/repositories/folder_repository.dart:97-112`](../lib/data/repositories/folder_repository.dart))
é o exemplo mais claro de por que `Result` existe: antes de tocar no banco,
ele sobe a árvore de pastas (`_isDescendant`) para recusar um movimento que
criaria um ciclo (pasta dentro de si mesma) — isso é regra de negócio pura,
zero SQL, e devolve `Err(ValidationFailure(...))` sem nunca ter chegado no
Drift. A `SnackBar` de erro que aparece na tela é literalmente o
`f.message` desse `Failure`.

## 5. Trocar cor/textura do azulejo — estado local otimista + gravação

[`widgets/tile_style_picker.dart:159-191`](../lib/widgets/tile_style_picker.dart)
mostra um padrão comum de "editor com preview ao vivo": o sheet guarda a
escolha atual em `State` local (`_color`, `_motif`) só para repintar o
preview na hora, e delega a gravação de verdade para quem abriu o sheet via
callback:

```dart
class _AppearanceSheetState extends State<_AppearanceSheet> {
  late TileColor? _color = widget.color;
  late TileMotif? _motif = widget.motif;
  ...
  onChanged: (c, m) {
    setState(() { _color = c; _motif = m; });  // repinta o preview já
    widget.onChanged(c, m);                     // e dispara a gravação
  },
```

Quem chama `showAppearanceSheet` (no menu ⋯ de `RecipeDetailPage` ou
`FolderPage`) passa como `onChanged` algo como
`(c, m) => ref.read(recipeRepositoryProvider).setAppearance(recipe.id, color: c, motif: m)`
— que cai em
[`RecipeRepository.setAppearance`](../lib/data/repositories/recipe_repository.dart:190),
grava `tileColor?.name`/`tileMotif?.name` (nulo em qualquer um volta ao
automático — §9.4 do plano) e sobe `updatedAt`. Como a tela de detalhe está
com `ref.watch(recipeDetailProvider(id))` observando o mesmo registro, o
card já aparece com a nova cor assim que o Drift confirma a escrita — sem o
sheet precisar devolver nada explicitamente para a tela de trás.

---

**Próximo:** [Vocabulário rápido](05-vocabulario.md) — glossário pra quando um
termo específico travar a leitura.
