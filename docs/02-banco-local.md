# O banco local

> Parte 2 de 5 do guia técnico. [Índice](../arquitetura-e-fluxo.md) ·
> anterior: [Visão geral e MVVM](01-visao-geral-e-mvvm.md).

## O que é, de fato

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
leitura da UI vem dele. Quando o bloco H (do plano) trouxer sync, o Supabase
vai ser uma cópia remota que se reconcilia com esse arquivo — o app continua
funcionando sem rede porque **já funciona assim hoje**.

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
   não cobre algo, como o FTS5 — ver abaixo). Erro de coluna vira erro de
   compilação, não erro em runtime.
3. **Streams reativos automáticos.** `select(recipes).watch()` devolve um
   `Stream<List<RecipeRow>>` que o Drift atualiza sozinho toda vez que uma
   escrita mexe na tabela `recipes` — é essa stream que sobe até o
   `StreamProvider` do Riverpod (ver [Riverpod e fluxo](03-riverpod-e-fluxo.md))
   e reconstrói a tela sem nenhum código de "recarregar".

## As tabelas que já existem

Definidas em [`data/database/tables.dart`](../lib/data/database/tables.dart),
todas registradas no `@DriftDatabase` de
[`data/database/app_database.dart`](../lib/data/database/app_database.dart):

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

## Migrações — como o schema evolui sem perder dado do usuário

`AppDatabase.schemaVersion` está em `3` agora. Cada vez que uma tabela muda,
esse número sobe, e o bloco `migration.onUpgrade` em
[`app_database.dart:87`](../lib/data/database/app_database.dart) descreve,
passo a passo, como sair da versão anterior:

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

## Busca por texto (FTS5)

A busca por nome/sobre/notas (`RF-01.9`) não usa `LIKE` — usa uma **tabela
virtual FTS5** (`recipes_fts`), que o Drift não modela nativamente, então ela
é criada via SQL cru no `onCreate` e mantida em sincronia por **triggers**
SQL (`AFTER INSERT/UPDATE/DELETE ON recipes`) — ver
[`app_database.dart:26-46`](../lib/data/database/app_database.dart). A consulta
em si roda como `customSelect(...)` em
[`daos/recipe_dao.dart:46`](../lib/data/database/daos/recipe_dao.dart), porque
é SQL específico de FTS5 que a API tipada do Drift não cobre. Isso é a
exceção deliberada à regra "sempre Drift tipado": FTS5 é rápido o bastante
(RNF-01) só por não fazer varredura sequencial de string.

## Soft delete e lixeira

`deletedAt` nulo = receita ativa. O DAO filtra `deletedAt.isNull()` em toda
query "normal" (`watchActive`, `findById`, etc.) e expõe `watchTrashed()`
separado. `softDelete` só grava a data; `hardDelete` de fato apaga a linha
(e o `ON DELETE CASCADE` das foreign keys leva ingredientes, passos e tags
junto). `RecipeRepository.purgeExpired` roda no boot
(`appBootstrapProvider`) e apaga de vez o que passou de 30 dias — best-effort,
uma falha aí não pode travar a abertura do app.

## Seed

No primeiro `onCreate`, `AppDatabase._seed()` insere ~30 unidades pt-BR,
categorias de corredor e o vocabulário de stopwords/qualificadores do
normalizador — nenhum ingrediente é semeado, de propósito (§6 do plano: a base
de ingredientes nasce do uso). O seed usa `insertOrIgnore` com IDs
determinísticos (`id: u.code`), então rodar de novo (`reseed()`, usado em
teste) não duplica nada.

---

## `Result`/`Failure`: por que não `try/catch` na UI

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

**Próximo:** [Riverpod e o fluxo](03-riverpod-e-fluxo.md) — os providers, a
navegação e um fluxo de ponta a ponta.
