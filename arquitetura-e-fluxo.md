# Receyta — Como o projeto funciona

> Guia técnico de orientação. Escrito para quem já mexeu com Flutter + MVVM mas
> está enferrujado. Explica o *porquê* de cada peça, não só o *onde*. Baseado no
> código real ao fim do bloco B — não no plano, embora os dois combinem.
> Referências de arquivo usam caminho relativo a partir de `lib/`.

---

## 1. A stack, em uma frase cada

| Peça | Pacote | Papel |
|---|---|---|
| Estado / DI | `flutter_riverpod` | Substitui `Provider`/`setState`/singletons manuais. Todo objeto compartilhado (banco, repositório, ViewModel) é um `Provider`. |
| Navegação | `go_router` | Rotas nomeadas por URL (`/recipe/:id`), com deep link de graça. |
| Models imutáveis | `freezed` | Gera `copyWith`, `==`, `toString` a partir de uma classe declarativa. Não tem lógica, só dados. |
| Banco local | `drift` (sobre `sqlite3`) | SQLite tipado: escreve Dart, o pacote gera SQL e classes de linha. |
| Erros esperados | `Result`/`Failure` (código próprio, `lib/core/result.dart`) | Repositório nunca lança exceção para a UI; devolve `Ok` ou `Err`. |

Nenhuma dessas é "a certa" objetivamente — são a combinação padrão para um app
Flutter offline-first orientado a dados relacionais. Se você já viu Riverpod +
Drift em outro projeto, o resto do documento vai soar familiar; se a última vez
que você mexeu com Flutter foi `Provider` + `sqflite` cru, as próximas seções
explicam a diferença.

---

## 2. MVVM aqui: o que cada camada pode e não pode fazer

```
View  →  ViewModel  →  Repository  →  DAO (Drift)  →  SQLite
                            ↓
                      Domain model (freezed)
```

**View** (`lib/features/*/[nome]_page.dart`) — só `Widget`. Lê estado de um
`Provider` via `ref.watch(...)`, dispara ação via `ref.read(...)`. Nunca
importa `drift` nem toca em SQL. Se você está escrevendo uma `Query` dentro de
um `build()`, está no lugar errado.

**ViewModel** (`lib/features/*/[nome]_view_model.dart`) — orquestra estado de
tela e comandos. Não conhece `BuildContext` nem `Widget`. No Receyta ele quase
sempre é uma classe fina que só repassa streams do repositório e expõe
`Provider`s Riverpod ao lado — ver `RecipesViewModel` em
[`features/recipes/recipes_view_model.dart`](lib/features/recipes/recipes_view_model.dart).
Telas com formulário (`RecipeFormViewModel`) guardam mais estado (rascunho
sendo editado), mas a regra é a mesma: zero Flutter.

**Repository** (`lib/data/repositories/*.dart`) — dono de um agregado
("receita", "pasta", "tag"). Converte `RecipeRow` (linha do banco) ↔ `Recipe`
(model de domínio), decide regra de negócio simples (ex.: soft delete grava
`deletedAt`, não apaga a linha) e devolve `Result<T>` em vez de lançar exceção.
Isso é a diferença mais importante em relação a um Repository "genérico" — veja
`RecipeRepository.saveDetail` em
[`data/repositories/recipe_repository.dart:95`](lib/data/repositories/recipe_repository.dart).

**DAO / Service** (`lib/data/database/daos/*.dart`) — acesso bruto ao SQLite
via API tipada do Drift. É aqui que existe `select()`, `where()`, `join()`,
`transaction()`. Um DAO não sabe o que é `Result` nem `Failure` — se algo dá
errado, ele deixa a exceção subir, e o Repository é quem converte para
`Failure`.

**Domain model** (`lib/domain/models/*.dart`) — `@freezed` puro. `Recipe`,
`RecipeIngredient`, `Tag`, etc. Não tem `id` de linha física nem nada do
Drift — é o que a UI e o ViewModel enxergam.

### Por que essa separação existe

Sem o Repository no meio, cada ViewModel reimplementaria a mesma lógica de
"ativo vs. na lixeira" ou "como vira `Recipe`". Com ele, o DAO pode até trocar
de Drift para outra coisa um dia sem a UI perceber — na prática isso nunca vai
acontecer neste projeto, mas o efeito colateral real e imediato é: **o
Repository é 100% testável com um banco de teste em memória, sem precisar
subir um widget**. É por isso que `RNF-06` (100% de cobertura em ViewModels e
no motor de ingredientes) é viável.

---

## 3. Riverpod: os quatro tipos de `Provider` que aparecem no código

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
  ([`data/database/database_provider.dart`](lib/data/database/database_provider.dart))

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
  ([`features/recipes/recipes_view_model.dart:58`](lib/features/recipes/recipes_view_model.dart))
  Repare que esse provider **depende de outro provider** (`selectedTagIdsProvider`)
  via `ref.watch`. Se o filtro de tag mudar, o Riverpod desmonta a stream
  antiga, assina a nova query no Drift automaticamente, e a UI recebe a nova
  lista — sem nenhum código explícito de "refazer a busca".

- **`StateProvider<T>`** — uma "caixinha" de estado mutável simples (um filtro,
  um texto de busca). Ex.: `selectedTagIdsProvider`, `searchQueryProvider`.
  A UI muda com `ref.read(x.notifier).state = novoValor`.

- **`FutureProvider<T>`** — como `StreamProvider`, mas para uma operação
  assíncrona que roda uma vez. `appBootstrapProvider`
  ([`bootstrap.dart`](lib/bootstrap.dart)) é o exemplo mais importante: a splash
  (`lib/router.dart`, rota `/splash`) faz `ref.watch(appBootstrapProvider.future)`
  e só navega para `/` quando o banco terminou de abrir, migrar e limpar a
  lixeira vencida.

`ProviderScope` em `main.dart` é a raiz que guarda todo esse cache — é
essencialmente o "container de DI" da árvore de widgets inteira.

---

## 4. O banco local: o que é, de fato

**SQLite** é um banco relacional que mora inteiro em **um arquivo** no disco
do aparelho — não é um servidor, não precisa de rede, não tem processo
separado. Cada usuário do Receyta tem o seu próprio arquivo, isolado, dentro
da pasta de documentos do app:

```dart
// data/database/connection.dart
final dir = await getApplicationDocumentsDirectory();
final file = File(p.join(dir.path, 'receyta.sqlite'));
return NativeDatabase.createInBackground(file);
```

Isso é literalmente o que "offline-first" significa na prática aqui: não
existe estado nenhum vivendo só em memória ou só num servidor. Toda escrita
vai para esse arquivo antes de a UI considerar a operação concluída, e toda
leitura da UI vem dele. Quando o bloco H trouxer sync, o Supabase vai ser uma
cópia remota que se reconcilia com esse arquivo — o app continua funcionando
sem rede porque **já funciona assim hoje**.

### Drift = SQLite + tipagem Dart + reatividade

Você poderia escrever SQL cru com o pacote `sqlite3` direto. O Drift existe
para três coisas:

1. **Tabelas viram classes Dart** (`lib/data/database/tables.dart`) — cada
   `class Recipes extends Table` gera, via `build_runner`, uma classe de linha
   (`RecipeRow`) com os campos certos e tipados. É por isso que existe
   `app_database.g.dart` e `recipe_dao.g.dart`: código gerado, nunca editado à
   mão. Se você mudar uma tabela, roda:
   ```
   dart run build_runner build --delete-conflicting-outputs
   ```
2. **Queries tipadas em Dart**, não strings SQL soltas (exceto quando o Drift
   não cobre algo, como o FTS5 — ver §4.3). Erro de coluna vira erro de
   compilação, não erro em runtime.
3. **Streams reativos automáticos.** `select(recipes).watch()` devolve um
   `Stream<List<RecipeRow>>` que o Drift atualiza sozinho toda vez que uma
   escrita mexe na tabela `recipes` — é essa stream que sobe até o
   `StreamProvider` do Riverpod (§3) e reconstrói a tela sem nenhum código
   de "recarregar".

### 4.1 As tabelas que já existem

Definidas em [`data/database/tables.dart`](lib/data/database/tables.dart),
todas registradas no `@DriftDatabase` de
[`data/database/app_database.dart`](lib/data/database/app_database.dart):

- `folders` — pastas, aninháveis (`parentId` referencia a própria tabela).
- `recipes` — a receita: nome, sobre, tempos, porções, notas, `folderId`,
  `isFavorite`, `deletedAt` (soft delete), `tileColor`/`tileMotif` (azulejo
  customizado, §9.4 do plano).
- `recipe_ingredients` / `recipe_steps` — listas ordenadas (`position`) e
  agrupáveis (`groupLabel`, ex. "Para a massa"), sempre com `recipeId`.
  `ingredientId` já existe na tabela mas fica nulo até o bloco C (parser)
  preenchê-lo — hoje só `rawText` é gravado.
- `ingredients` / `ingredient_aliases` / `units` / `categories` /
  `normalizer_terms` — o esqueleto do motor de normalização do bloco C.
  Existem no schema desde o bloco A, mas ainda não têm dado de receita real
  ligado a eles.
- `tags` / `recipe_tags` — tabela de junção N:N clássica.
- `meal_plan_entries`, `shopping_lists`, `shopping_list_items`,
  `shopping_item_sources` — reservadas para os blocos F e E; existem no schema
  mas nenhuma tela ainda escreve nelas.

Todo ID é `TEXT` (UUID v4, gerado com o pacote `uuid` no Repository — nunca no
DAO). Todo agregado sincronizável tem `createdAt`/`updatedAt` desde já, mesmo
sem sync, porque adicionar essas colunas depois seria uma migração dolorosa.

### 4.2 Migrações — como o schema evolui sem perder dado do usuário

`AppDatabase.schemaVersion` está em `3` agora. Cada vez que uma tabela muda,
esse número sobe, e o bloco `migration.onUpgrade` em
[`app_database.dart:87`](lib/data/database/app_database.dart) descreve, passo a
passo, como sair da versão anterior:

```dart
onUpgrade: (m, from, to) async {
  if (from < 2) { /* recipe_ingredients.ingredient_id vira nullable */ }
  if (from < 3) { /* recipes/folders ganham tile_color, tile_motif */ }
},
```

Isso roda automaticamente na abertura do banco, na versão instalada do
usuário — é o motivo de nunca poder simplesmente apagar/recriar uma tabela em
produção. `A8` no plano cobre o teste automatizado disso (migração N→N+1 com
dado de exemplo, verificando que nada se perde).

### 4.3 Busca por texto (FTS5)

A busca por nome/sobre/notas (`RF-01.9`) não usa `LIKE` — usa uma **tabela
virtual FTS5** (`recipes_fts`), que o Drift não modela nativamente, então ela
é criada via SQL cru no `onCreate` e mantida em sincronia por **triggers**
SQL (`AFTER INSERT/UPDATE/DELETE ON recipes`) — ver
[`app_database.dart:26-46`](lib/data/database/app_database.dart). A consulta em
si roda como `customSelect(...)` em
[`daos/recipe_dao.dart:46`](lib/data/database/daos/recipe_dao.dart), porque é
SQL específico de FTS5 que a API tipada do Drift não cobre. Isso é a exceção
deliberada à regra "sempre Drift tipado": FTS5 é rápido o bastante (RNF-01)
só por não fazer varredura sequencial de string.

### 4.4 Soft delete e lixeira

`deletedAt` nulo = receita ativa. O DAO filtra `deletedAt.isNull()` em toda
query "normal" (`watchActive`, `findById`, etc.) e expõe `watchTrashed()`
separado. `softDelete` só grava a data; `hardDelete` de fato apaga a linha
(e o `ON DELETE CASCADE` das foreign keys leva ingredientes, passos e tags
junto). `RecipeRepository.purgeExpired` roda no boot
(`appBootstrapProvider`) e apaga de vez o que passou de 30 dias — best-effort,
uma falha aí não pode travar a abertura do app.

### 4.5 Seed

No primeiro `onCreate`, `AppDatabase._seed()` insere ~30 unidades pt-BR,
categorias de corredor e o vocabulário de stopwords/qualificadores do
normalizador — nenhum ingrediente é semeado, de propósito (§6 do plano: a base
de ingredientes nasce do uso). O seed usa `insertOrIgnore` com IDs
determinísticos (`id: u.code`), então rodar de novo (`reseed()`, usado em
teste) não duplica nada.

---

## 5. `Result`/`Failure`: por que não `try/catch` na UI

`lib/core/result.dart` define um `sealed class Result<T>` com dois filhos,
`Ok<T>` e `Err<T>`. Todo método de Repository que pode falhar devolve
`Future<Result<T>>`, nunca lança. Quem chama é obrigado a tratar os dois
casos (o compilador reclama de `switch` não-exaustivo se você esquecer):

```dart
final result = await recipeRepository.saveDetail(...);
result.when(
  ok: (recipe) => context.go('/recipe/${recipe.id}'),
  err: (failure) => showSnackBar(failure.message),
);
```

`Failure` também é `sealed` (`DatabaseFailure`, `NotFoundFailure`,
`ValidationFailure`), então o tratamento pode diferenciar "não achei" de "erro
de banco" sem `is` solto. Isso é Dart puro — sem dependência de Flutter — o
que permite testar Repository sem widget nenhum, só com
`AppDatabase.forTesting(NativeDatabase.memory())`.

Streams (`watchAll`, `watchDetail`) **não** usam `Result` — elas assumem que
uma leitura reativa não falha de forma que a UI precise reagir (se falhar, é
bug, não caso de negócio). `Result` aparece só em operações pontuais de
escrita/leitura única.

---

## 6. `freezed`: por que os models são assim

```dart
@freezed
class Recipe with _$Recipe {
  const factory Recipe({
    required String id,
    required String name,
    ...
    @Default(false) bool isFavorite,
  }) = _Recipe;
}
```

`freezed` lê essa declaração e gera `recipe.freezed.dart` com: construtor
imutável, `copyWith` (`recipe.copyWith(name: 'novo nome')` sem mexer nos outros
campos), `==`/`hashCode` por valor (dois `Recipe` com os mesmos campos são
iguais, o que faz o Riverpod evitar rebuild desnecessário quando uma stream
emite um valor "igual" ao anterior), e `toString` legível para debug. Você
nunca edita o `.freezed.dart` — ele é regenerado pelo `build_runner` toda vez
que a classe original muda.

Isso é o motivo de o `import/export` em JSON (bloco D) "vir de graça" mais pra
frente: basta acoplar `json_serializable` na mesma classe.

---

## 7. Navegação: `go_router`

Rotas são declaradas uma vez em [`router.dart`](lib/router.dart), por **path**
(`/recipe/:id`), não por push imperativo de `Widget`:

```dart
GoRoute(path: '/recipe/:id', name: 'recipe-detail',
    builder: (context, state) => RecipeDetailPage(recipeId: state.pathParameters['id']!)),
```

Navegar é `context.go('/recipe/$id')` ou `context.push(...)`. A vantagem sobre
`Navigator.push` direto: cada tela tem uma URL real, o que é pré-requisito
para "abrir um `.json` compartilhado por outro app" (D5) e para deep link em
geral — a URL já existe, só falta o handler de intent.

`RootBackGuard` (em torno da `HomeShell` na rota `/`) intercepta o botão
"voltar" do Android na tela raiz para não fechar o app sem confirmação/estado
esperado — é UI, não roteamento em si.

---

## 8. Trilhando um fluxo completo: salvar uma receita

Para fixar como as camadas conversam, aqui está o caminho real de "usuário
aperta salvar no formulário" até "a lista da home atualiza sozinha":

1. **View** — `RecipeFormPage` chama algo como
   `ref.read(recipeFormViewModelProvider.notifier).save()`.
2. **ViewModel** (`RecipeFormViewModel`) já tem o estado do formulário (nome,
   linhas de ingrediente digitadas, etc.) e chama
   `recipeRepository.saveDetail(name: ..., ingredientLines: [...], ...)`.
3. **Repository** (`RecipeRepository.saveDetail`,
   [`data/repositories/recipe_repository.dart:95`](lib/data/repositories/recipe_repository.dart)):
   - monta um `Recipe` novo (`Uuid().v4()`, timestamps UTC) ou copia o
     existente (`base.copyWith(...)`) se for edição;
   - transforma cada linha de texto em um `RecipeIngredientRow`/`RecipeStepRow`
     com `position` sequencial e `groupLabel`;
   - resolve as tags digitadas para IDs via `TagDao.ensureTags` (getOrCreate
     por nome);
   - chama `_dao.saveWithChildren(...)` — e só aí toca em Drift de fato;
   - devolve `Ok(recipe)` ou `Err(DatabaseFailure(...))`.
4. **DAO** (`RecipeDao.saveWithChildren`,
   [`data/database/daos/recipe_dao.dart:114`](lib/data/database/daos/recipe_dao.dart)):
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

## 9. Estrutura de pastas — o que existe hoje

```
lib/
  main.dart                entrypoint: ProviderScope + MaterialApp.router
  router.dart               rotas go_router
  bootstrap.dart            appBootstrapProvider (abre banco, migra, purga lixeira)
  splash.dart               animação de abertura
  home_shell.dart           shell com PillNavBar
  root_back_guard.dart      intercepta back button na raiz
  messenger.dart            chave global de SnackBar
  app_assets.dart           constantes de caminho de asset

  core/
    result.dart             Result/Ok/Err/Failure
    tag_name.dart           canonicalTagName (normalização Title Case pt-BR)
    tile_style.dart         enums TileColor/TileMotif + (de)serialização por nome

  data/
    database/
      tables.dart           definição das tabelas Drift
      app_database.dart     @DriftDatabase, migrations, seed
      connection.dart       abre o arquivo .sqlite (nativo)
      database_provider.dart  Provider<AppDatabase>
      seed_data.dart        listas de unidades/categorias/termos semeados
      daos/                 RecipeDao, FolderDao, TagDao (+ .g.dart gerados)
    repositories/
      recipe_repository.dart, folder_repository.dart, tag_repository.dart

  domain/models/            Recipe, RecipeDetail, RecipeIngredient, RecipeStep,
                            Tag, Folder — todos @freezed (+ .freezed.dart gerados)

  features/
    recipes/                lista, detalhe, formulário, busca, tags, lixeira,
                            modo cozinha — view + view_model por tela
    folders/                pasta, drag-and-drop, seletor de pasta

  theme/                    tokens.dart, typography.dart, app_theme.dart
  widgets/                  componentes compartilhados (RecipeCard, TilePattern, ...)
  gallery_app.dart          entrypoint alternativo: galeria de componentes fora do app
```

Note que `domain/engine/` (parser, normalizer, matcher — bloco C) e
`features/planner/`, `features/shopping/`, `features/io/` **ainda não
existem**. Eles nascem quando o primeiro arquivo de cada bloco for escrito —
não crie a pasta vazia antes disso (ver `[[foco-implementacao]]` /
convenção do projeto de não criar estrutura especulativa).

---

## 10. Onde mexer quando quiser adicionar algo

Perguntas rápidas de orientação, já que isso costuma ser o que trava quem
está reaprendendo a arquitetura:

- **"Quero adicionar um campo na receita."** → coluna nova em `tables.dart`
  (`Recipes`) → sobe `schemaVersion`, adiciona `if (from < N)` em
  `migration.onUpgrade` → `dart run build_runner build` → campo novo em
  `Recipe` (freezed) → mapear nos dois sentidos em
  `RecipeRepository._toDomain`/`_toRow` → expor no formulário.
- **"Quero uma tela nova."** → pasta em `features/<algo>/`, rota nova em
  `router.dart`, ViewModel fino que só expõe `Provider`s do Repository
  existente (se o dado já existe) ou um Repository novo (se for agregado
  novo).
- **"Quero mudar uma cor/raio/fonte."** → só em `lib/theme/tokens.dart` ou
  `typography.dart` — nunca hardcoded em widget (RNF-10 é checado por lint).
- **"Como eu testo isso sem rodar o app?"** → Repository e DAO testam com
  `AppDatabase.forTesting(NativeDatabase.memory())`, sem `WidgetTester`.
  ViewModel sem Flutter (a maioria) testa igual, puro Dart. Só teste de
  widget precisa montar árvore Flutter de verdade.

---

## 11. Exemplos de uso reais, trilhados na View

A §8 trilhou "salvar uma receita" partindo do ViewModel. Esta seção faz o
inverso: parte do `Widget` de verdade — o que aparece na tela — e mostra a
linha exata que liga toque → provider → repositório → banco. É a parte que
mais ajuda a "destravar" quando você está lendo uma tela pela primeira vez.

### 11.1 Filtro por tag/favoritos na home — providers encadeados

Em [`features/recipes/recipes_page.dart:282-297`](lib/features/recipes/recipes_page.dart),
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
[`features/recipes/recipes_view_model.dart:58-69`](lib/features/recipes/recipes_view_model.dart):

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

### 11.2 Busca com debounce — separar "o que aparece no campo" de "o que dispara query"

[`features/recipes/search_page.dart:42-56`](lib/features/recipes/search_page.dart)
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
  `RecipeDao.search`, §4.3) — sem o debounce, cada tecla digitada rápido
  geraria uma consulta ao banco desperdiçada.

Isso ilustra uma regra geral: **nem todo estado de tela precisa ser
Riverpod.** Estado que não tem por que ser observado por outra parte do app
(texto de um campo, posição de scroll) fica em `State` local do
`ConsumerStatefulWidget`; só o que alimenta uma query ou é compartilhado entre
telas vira `Provider`.

### 11.3 Lixeira — duas ações, dois métodos de Repository, sem `Result` na tela

[`features/recipes/trash_page.dart:110-119`](lib/features/recipes/trash_page.dart):

```dart
final repo = ref.read(recipeRepositoryProvider);   // read, não watch: é uma ação, não uma leitura reativa
...
IconButton(onPressed: () => repo.restore(r.id), ...),
IconButton(onPressed: () => repo.deleteForever(r.id), ...),
```

Repare que aqui a tela **ignora** o `Result` que `restore`/`deleteForever`
devolvem — não trata `err`. É uma escolha aceitável porque essas operações
praticamente não falham em uso normal (é update por `id` já existente na
tela) e uma falha nelas não deixa o usuário travado. Compare com
`FolderDropZone` (§11.4 abaixo), que trata os dois lados porque mover pra
pasta *pode* falhar por regra de negócio (ciclo). A régua não é "sempre trate
o `Err`", é "trate quando o `Err` for algo que o usuário precisa saber para
agir diferente".

A lista em si (`trashed = ref.watch(trashedRecipesProvider)`) é a mesma
mecânica de stream de sempre — `RecipeDao.watchTrashed()` filtra
`deletedAt.isNotNull()` (§4.4) e atualiza sozinha quando `restore` ou
`deleteForever` mexem na tabela.

### 11.4 Arrastar receita para pasta — `Result` tratado nos dois lados

O drag-and-drop (`features/folders/recipe_drag.dart`) é `Draggable` +
`DragTarget` do Flutter puro por baixo, mas o ponto interessante é o que
acontece ao soltar, em
[`recipe_drag.dart:287-298`](lib/features/folders/recipe_drag.dart):

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
([`data/repositories/folder_repository.dart:97-112`](lib/data/repositories/folder_repository.dart))
é o exemplo mais claro de por que `Result` existe: antes de tocar no banco,
ele sobe a árvore de pastas (`_isDescendant`) para recusar um movimento que
criaria um ciclo (pasta dentro de si mesma) — isso é regra de negócio pura,
zero SQL, e devolve `Err(ValidationFailure(...))` sem nunca ter chegado no
Drift. A `SnackBar` de erro que aparece na tela é literalmente o
`f.message` desse `Failure`.

### 11.5 Trocar cor/textura do azulejo — estado local otimista + gravação

[`widgets/tile_style_picker.dart:159-191`](lib/widgets/tile_style_picker.dart)
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
[`RecipeRepository.setAppearance`](lib/data/repositories/recipe_repository.dart:190),
grava `tileColor?.name`/`tileMotif?.name` (nulo em qualquer um volta ao
automático — §9.4 do plano) e sobe `updatedAt`. Como a tela de detalhe está
com `ref.watch(recipeDetailProvider(id))` observando o mesmo registro, o
card já aparece com a nova cor assim que o Drift confirma a escrita — sem o
sheet precisar devolver nada explicitamente para a tela de trás.

---

## 12. Vocabulário rápido (pra quem está enferrujado)

- **DTO** — no plano (§5) é mencionado como camada entre Repository e
  remoto; hoje, sem bloco H, o Repository conversa direto com `RecipeRow`
  (a "linha" gerada pelo Drift) fazendo as vezes de DTO local.
  Um DTO de verdade (JSON do backend) só aparece no bloco H.
- **Stream vs. Future** — `Future<T>` resolve uma vez; `Stream<T>` pode emitir
  vários valores ao longo do tempo. Toda leitura que a UI precisa manter
  atualizada (lista de receitas, detalhe de uma receita) é `Stream`; toda
  operação pontual (salvar, favoritar, apagar) é `Future<Result<T>>`.
- **Migração** — script que transforma o schema da versão N para N+1 sem
  apagar dado existente do usuário já instalado (§4.2).
- **Soft delete** — "apagar" que só marca `deletedAt`, permitindo desfazer
  dentro do prazo (30 dias, RF-01.6); `hardDelete` é o apagar de verdade.
- **Offline-first** — não é "funciona offline também"; é "o dispositivo é a
  fonte de verdade primária SEMPRE", e qualquer sync futuro é uma camada por
  cima que reconcilia, nunca um pré-requisito para a operação funcionar.
