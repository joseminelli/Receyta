# Visão geral e MVVM

> Parte 1 de 7 do guia técnico. [Índice](../arquitetura-e-fluxo.md).

## A stack, em uma frase cada

| Peça | Pacote | Papel |
|---|---|---|
| Estado / DI | `flutter_riverpod` | Substitui `Provider`/`setState`/singletons manuais. Todo objeto compartilhado (banco, repositório, ViewModel) é um `Provider`. |
| Navegação | `go_router` | Rotas nomeadas por URL (`/recipe/:id`), com deep link de graça. |
| Models imutáveis | `freezed` | Gera `copyWith`, `==`, `toString` a partir de uma classe declarativa. Não tem lógica, só dados. |
| Banco local | `drift` (sobre `sqlite3`) | SQLite tipado: escreve Dart, o pacote gera SQL e classes de linha. |
| Erros esperados | `Result`/`Failure` (código próprio, `lib/core/result.dart`) | Repositório nunca lança exceção para a UI; devolve `Ok` ou `Err`. |

Nenhuma dessas é "a certa" objetivamente — são a combinação padrão para um app
Flutter offline-first orientado a dados relacionais. Se você já viu Riverpod +
Drift em outro projeto, o resto do guia vai soar familiar; se a última vez que
você mexeu com Flutter foi `Provider` + `sqflite` cru, os outros arquivos
explicam a diferença (banco local e Riverpod têm arquivo próprio, ver índice).

---

## MVVM aqui: o que cada camada pode e não pode fazer

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
[`features/recipes/recipes_view_model.dart`](../lib/features/recipes/recipes_view_model.dart).
Telas com formulário (`RecipeFormViewModel`) guardam mais estado (rascunho
sendo editado), mas a regra é a mesma: zero Flutter.

**Repository** (`lib/data/repositories/*.dart`) — dono de um agregado
("receita", "pasta", "tag"). Converte `RecipeRow` (linha do banco) ↔ `Recipe`
(model de domínio), decide regra de negócio simples (ex.: soft delete grava
`deletedAt`, não apaga a linha) e devolve `Result<T>` em vez de lançar exceção
(detalhes de `Result` no arquivo do [banco local](02-banco-local.md)). Isso é
a diferença mais importante em relação a um Repository "genérico" — veja
`RecipeRepository.saveDetail` em
[`data/repositories/recipe_repository.dart:95`](../lib/data/repositories/recipe_repository.dart).

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

### `freezed`: por que os models são assim

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

Isso é o motivo de o `import/export` em JSON (bloco D do plano) "vir de graça"
mais pra frente: basta acoplar `json_serializable` na mesma classe.

---

## Estrutura de pastas — o que existe hoje

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
      daos/                 RecipeDao, FolderDao, TagDao, IngredientDao (+ .g.dart gerados)
    repositories/
      recipe_repository.dart, folder_repository.dart, tag_repository.dart,
      ingredient_repository.dart
    services/
      recipe_import_service.dart   busca URL + extrai receita (C7)
      recipe_ocr_service.dart      foto → OCR → receita (C8)

  domain/
    models/                Recipe, RecipeDetail, RecipeIngredient, RecipeStep,
                            Tag, Folder, Ingredient — todos @freezed (+ .freezed.dart gerados)
    engine/                parser/normalizer/fuzzy match de ingrediente (C1-C4)
                            + extração de receita de HTML/OCR (C7-C8), Dart
                            puro — ver [motor de ingredientes](../docs/06-motor-de-ingredientes.md)
                            e [importação](../docs/07-importacao-de-receitas.md)

  features/
    recipes/                lista, detalhe, formulário, busca, tags, lixeira,
                            modo cozinha, gerenciar ingredientes, import de
                            link/foto — view + view_model por tela
    folders/                pasta, drag-and-drop, seletor de pasta

  theme/                    tokens.dart, typography.dart, app_theme.dart
  widgets/                  componentes compartilhados (RecipeCard, TilePattern, ...)
  gallery_app.dart          entrypoint alternativo: galeria de componentes fora do app
```

`domain/engine/` nasceu no bloco C (primeiro arquivo: `ingredient_parser.dart`,
C1). `features/planner/`, `features/shopping/`, `features/io/` **ainda não
existem** — nascem quando o primeiro arquivo do bloco correspondente for
escrito, não antes (convenção do projeto de não criar estrutura
especulativa).

---

## Onde mexer quando quiser adicionar algo

Perguntas rápidas de orientação, já que isso costuma ser o que trava quem
está reaprendendo a arquitetura:

- **"Quero adicionar um campo na receita."** → coluna nova em `tables.dart`
  (`Recipes`) → sobe `schemaVersion`, adiciona `if (from < N)` em
  `migration.onUpgrade` (ver [banco local](02-banco-local.md)) →
  `dart run build_runner build` → campo novo em `Recipe` (freezed) → mapear
  nos dois sentidos em `RecipeRepository._toDomain`/`_toRow` → expor no
  formulário.
- **"Quero uma tela nova."** → pasta em `features/<algo>/`, rota nova em
  `router.dart` (ver [Riverpod e fluxo](03-riverpod-e-fluxo.md)), ViewModel
  fino que só expõe `Provider`s do Repository existente (se o dado já existe)
  ou um Repository novo (se for agregado novo).
- **"Quero mudar uma cor/raio/fonte."** → só em `lib/theme/tokens.dart` ou
  `typography.dart` — nunca hardcoded em widget (RNF-10 é checado por lint).
- **"Como eu testo isso sem rodar o app?"** → Repository e DAO testam com
  `AppDatabase.forTesting(NativeDatabase.memory())`, sem `WidgetTester`.
  ViewModel sem Flutter (a maioria) testa igual, puro Dart. Só teste de
  widget precisa montar árvore Flutter de verdade.

---

**Próximo:** [O banco local](02-banco-local.md) — o que é SQLite na prática,
Drift, migrações, busca e a lixeira.
