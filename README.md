<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/joseminelli/Receyta/refs/heads/main/assets/brand/logoInverted.png?token=GHSAT0AAAAAAEFNU4KO5TX4UVK67GZX3XYO2VDMCGQ">
  <img src="https://raw.githubusercontent.com/joseminelli/Receyta/refs/heads/main/assets/brand/logo.png?token=GHSAT0AAAAAAEFNU4KPJGPB5OAVCY2SAA5I2VDMCHA" alt="Receyta" width="360">
</picture>

### Um caderno de receitas que funciona sem internet.

Cadastre receitas, organize em pastas, planeje a semana e saia pro mercado com a
lista pronta — tudo local, tudo rápido, tudo em português.

`Flutter` · `Riverpod` · `Drift (SQLite)` · `offline-first`

</div>

---

## Telas

<table>
  <tr>
    <td width="25%"><img src="https://raw.githubusercontent.com/joseminelli/Receyta/refs/heads/main/images/preview/MainPage.png?token=GHSAT0AAAAAAEFNU4KPNQJUA6VMBBZL5G3S2VDMBQQ" alt="Home"></td>
    <td width="25%"><img src="https://raw.githubusercontent.com/joseminelli/Receyta/refs/heads/main/images/preview/P%C3%A1ginaReceita.png?token=GHSAT0AAAAAAEFNU4KPA3TOA7L3ZLRLNG4C2VDMBWA" alt="Detalhe da receita"></td>
    <td width="25%"><img src="https://raw.githubusercontent.com/joseminelli/Receyta/refs/heads/main/images/preview/PassosReceita.png?token=GHSAT0AAAAAAEFNU4KPY5Z7B3JPFPPX6M3W2VDMB3Q" alt="Passos de preparo"></td>
    <td width="25%"><img src="https://raw.githubusercontent.com/joseminelli/Receyta/refs/heads/main/images/preview/modoCozinha.png?token=GHSAT0AAAAAAEFNU4KP73VYVZD274GRXHAA2VDMB6Q" alt="Modo cozinha"></td>
  </tr>
  <tr>
    <td align="center"><b>Home</b><br><sub>cabeçalho de azulejo, filtro de tags, faixa de pastas, destaque em "Recentes"</sub></td>
    <td align="center"><b>Detalhe</b><br><sub>hero na cor escolhida, métricas gigantes, ingredientes com separador de seção</sub></td>
    <td align="center"><b>Preparo</b><br><sub>passos numerados, seções "Bolo" / "Calda" na fonte display</sub></td>
    <td align="center"><b>Modo cozinha</b><br><sub>tela escura que não apaga, passos grandes, ingredientes a um toque</sub></td>
  </tr>
</table>

---

## O que é

Receyta é um app de receitas para uso pessoal e familiar. A premissa: o telefone
já vive na cozinha, então o app tem que abrir rápido, funcionar com a mão suja e
não depender de sinal. Nada de login pra começar, nada de anúncio, nada de
"salve na nuvem pra continuar".

O design foge do padrão *card com foto de banco de imagens*: no lugar da foto,
cada receita ganha um bloco de cor com um azulejo modernista (inspirado em Athos
Bulcão), e os números — tempo de preparo, porções, passo atual — aparecem em
escala enorme. É um **caderno**, não um feed.

---

## O que o app faz

### Receitas
- **Cadastro progressivo** — cria só com o nome e vai preenchendo: sobre, tempo
  de preparo, tempo de fogão, rendimento, notas.
- **Ingredientes e passos como texto livre** — cola do WhatsApp e reordena
  arrastando. O texto original nunca é perdido.
- **Separadores de seção** — "Para a massa", "Para o recheio": marque uma linha
  como separador e as de baixo entram naquele grupo, no cadastro e na leitura.
- **Tela de detalhe** feita pra cozinhar: métricas grandes, ingredientes,
  preparo numerado, tudo em fundo chapado (padrão nunca fica atrás de texto que
  se lê linha a linha).
- **Modo cozinha** — tela que não apaga (wakelock, com aviso visível), passos em
  cartões grandes que você rola e marca como feito, ingredientes a um toque.
- **Favoritar** e **lixeira de 30 dias** — nada é apagado de verdade antes do
  prazo; dá pra restaurar.
- **Aparência personalizável** — escolha a cor e a textura do azulejo de cada
  receita (ou deixe no automático, derivado do id).

### Busca e organização
- **Busca instantânea** (SQLite FTS5) por nome, sobre, notas e tag.
- **Tags livres** com filtro horizontal na home e tela de gerenciamento.
- **Pastas aninhadas** — crie, renomeie, mova, aninhe. A home mostra só as
  receitas soltas; o resto vive nas pastas.
- **Arrastar e soltar** — segure um card e solte numa pasta pra guardar;
  segure uma pasta e solte em outra pra aninhar; solte na barra "tirar da
  pasta" pra subir um nível.
- **Menu `+` expansível** no cabeçalho: "Nova receita" ou "Nova pasta".

### Planejado (mesma base de dados, próximos blocos)
- **Lista de compras** — gera a lista de várias receitas, soma quantidades
  compatíveis (500g + 800g = 1,3kg), agrupa por corredor do mercado, tela
  escura pra usar com uma mão só.
- **Calendário semanal** — agende receitas por dia e refeição, gere a lista de
  compras da semana inteira.
- **Sugestões** — "que tal isso hoje?" com o motivo explicado (similaridade de
  ingredientes por IDF).
- **Import / export** — uma receita em JSON pelo share sheet, backup completo,
  PDF pra impressão, import de URL de sites de receita.
- **Motor de ingredientes** — parser de quantidade/unidade e normalização
  ("tomates" e "tomate" viram o mesmo item) pra destravar compras e sugestão.
- **Fotos de receita** — com armazenamento na nuvem (Supabase Storage), junto
  do sync opcional entre aparelhos.

---

## Arquitetura

Camadas com dependência de mão única. A regra de negócio nunca sobe pra View, e
o Flutter nunca desce pro ViewModel.

```
View  ─▶  ViewModel  ─▶  Repository  ─▶  Service (DAO / HTTP / FS)
   (widgets)   (estado, comandos)   (fonte de verdade      (acesso bruto)
                                     de um agregado)
                          │
                          ▼
                   Domain models (freezed)
```

| Camada | Responsabilidade | Regra |
|---|---|---|
| **View** | Só widgets. | Sem regra de negócio, sem acesso a repositório. |
| **ViewModel** | Estado da tela, comandos, orquestração. | Não conhece Flutter — nada de `BuildContext`. |
| **Repository** | Fonte de verdade de um agregado (receitas, pastas, tags). Converte linha do banco ↔ modelo de domínio. Traduz erro de banco em `Failure`. | Timestamps sempre em UTC. |
| **Service** | DAOs do Drift, cliente HTTP, sistema de arquivos. | — |

O diretório **`lib/domain/engine/`** (parser, normalizador, agregador de compras,
similaridade) é **Dart puro** — sem Flutter, sem Drift — então roda em unit test
rápido, sem emulador.

### Padrões transversais

- **`Result<T>` / `Failure`** — operações que podem falhar de forma esperada
  devolvem `Ok(value)` / `Err(failure)`; o consumidor faz `switch` exaustivo.
  Sem exceção pra fluxo de controle.
- **Riverpod** pra injeção e estado. `Provider` pros repositórios,
  `StreamProvider` pras listas que vêm do banco (o Drift emite de novo sozinho
  quando a tabela muda), `StateProvider` pros filtros de UI.
- **go_router** com o `router` como `final` de topo — rotas novas pedem *hot
  restart*, não *hot reload*.
- **freezed** pros modelos de domínio imutáveis.

### Estrutura

```
lib/
  main.dart              bootstrap: abre o Drift, roda migração + seed, libera a home
  router.dart            go_router
  gallery_app.dart       entrypoint alternativo — galeria de componentes isolada
  theme/                 tokens.dart · typography.dart · app_theme.dart
  core/                  result.dart · tag_name.dart · tile_style.dart
  data/
    database/            tables.dart · app_database.dart · daos/
    repositories/        recipe · folder · tag
  domain/
    models/              freezed: Recipe, RecipeDetail, RecipeIngredient, RecipeStep, Folder, Tag
    engine/              (bloco C) parser · normalizer · aggregator · similarity
  features/
    recipes/             view + viewmodel de cada tela
    folders/
  widgets/               componentes compartilhados (cards, azulejo, navbar, pickers)
```

Imports internos usam `package:receyta/...` — mover arquivo não quebra caminho.

### Banco de dados

**Drift** sobre SQLite, schema versionado (hoje **v3**).

- Timestamps gravados como **texto ISO-8601 UTC** — legível no arquivo, sem
  ambiguidade de fuso quando o sync chegar.
- **FTS5** externo sobre `recipes`, mantido em sincronia por *triggers*, pra
  busca por nome/sobre/notas.
- **Soft delete** (`deleted_at`) escondido no DAO — o repositório nem sabe que a
  linha continua lá; uma faxina no boot apaga o que passou dos 30 dias.
- Migrações testadas com dados reais a cada `v(N-1) → vN`
  (`SchemaVerifier` + snapshots em `drift_schema/`).

---

## Design system

> **Maximalismo moderno.** Densidade alta e cor saturada, mas o ornamento vem de
> escala tipográfica e blocos de cor — nunca de textura aplicada ou moldura.

- **Sem bordas, sem sombra, sem gradiente.** Superfícies chapadas; separação por
  bloco de cor e raio grande.
- **Números são ilustração.** Tempo de fogão, porções e índice de passo aparecem
  gigantes, sangrando na borda do bloco — é o dado real ampliado que resolve o
  card sem foto.
- **Salto de escala extremo.** Display de 44–52px ao lado de label de 10px.

### Cor tem papel semântico

Você sabe **onde está** antes de ler o título.

| Token | Papel |
|---|---|
| `coral` | Seção **Receitas**, hero de receita |
| `violet` | Seção **Semana**, blocos de sugestão |
| `ink` | Seção **Compras** (a tela escura, usada no mercado), navbar, tipografia |
| `lime` | Ação primária, estado ativo, destaque sobre `ink` |
| `paper` / `paperSoft` | Superfícies claras |

Regras fixas: `lime` nunca sobre `paper`; no máximo duas cores saturadas por
tela; texto sobre bloco saturado é branco puro.

### Tipografia

- **Display** — Bricolage Grotesque **800**, `letter-spacing: -0.045em`. Nomes
  de receita, títulos, números. O tracking negativo agressivo é a assinatura.
- **Interface** — sans do sistema, 400/500, nunca acima. Corpo, labels, botões.
- Fonte empacotada como asset local — nunca baixada em runtime (sem FOUT, sem
  dependência de rede).

### Azulejo modernista

Quatro módulos geométricos (`arco`, `meiaLua`, `diagonal`, `ponto`), inspirados
em Athos Bulcão — geometria pura, sem floral, sem moldura. Cada um emparelha com
uma cor (`arco`+coral, `meiaLua`+violet, `diagonal`+ink, `ponto`+lime), mas o
usuário pode recombinar.

- Entra **só** em blocos que substituem foto: hero de receita, tile de pasta,
  canto de cabeçalho.
- **Nunca** atrás de texto corrido, lista de ingredientes ou barra de navegação.
- Tom sobre tom, contraste ~12%. É a camada mais fraca da hierarquia.
- Rasterizado uma vez por `(módulo, cores, tile, dpr)` e reusado como *shader*
  repetido — 60 cards custam uma `drawRect` cada, não um path por pixel.

---

## Rodando o projeto

### Pré-requisitos

- **Flutter 3.27.x** (canal stable) · Dart `^3.6`
- Um emulador/dispositivo Android ou iOS

### Primeira vez

```bash
flutter pub get

# gera o código do Drift, do freezed e do Riverpod
dart run build_runner build --delete-conflicting-outputs
```

O código gerado (`*.g.dart`, `*.freezed.dart`) **é commitado** — a CI recusa PR
que mude `tables.dart` ou um `@freezed` sem regenerar.

### Rodar o app

```bash
flutter run
```

### Galeria de componentes (fora do app)

```bash
flutter run -t lib/gallery_app.dart
```

Cada componente compartilhado (`SectionHeader`, `PillButton`, `PillNavBar`,
`TilePattern`, cards…) tem uma página própria, navegável sem abrir o app.

### Benchmark do azulejo

```bash
flutter run --profile -t lib/gallery_app.dart
# abrir "TilePattern — benchmark", rolar 60 cards, conferir o overlay de
# performance (nenhum frame acima de 16ms)
```

### Assets de marca

```bash
# splash nativa (a animada é lib/splash.dart)
dart run flutter_native_splash:create

# ícone: iOS, Android legado + adaptativo, web
dart run flutter_launcher_icons
```

---

## Testes

```bash
flutter analyze
flutter test                                   # suíte inteira
flutter test test/data/repositories/           # um diretório
flutter test test/features/folders/folder_page_test.dart   # um arquivo
```

### Como os testes de banco funcionam

`flutter test` roda na Dart VM, sem plugins nativos — então o `sqlite3` que o
app usa via `sqlite3_flutter_libs` não existe. `test/flutter_test_config.dart`
resolve apontando o *loader* pra uma lib do sistema (`winsqlite3.dll` no
Windows, `libsqlite3.so.0` no Linux; a CI instala `libsqlite3-0`). O pacote
`sqlite3` está em `dev_dependencies` só por isso.

Cada teste usa `AppDatabase.forTesting(NativeDatabase.memory())` — banco
isolado, em memória, descartado no `tearDown`.

### O que é coberto

| Área | Exemplos |
|---|---|
| **Repositórios** | CRUD de receita, tags reaproveitadas entre receitas, soft delete + restore + purge, busca FTS, pastas (mover, aninhar, barrar ciclo) |
| **ViewModels** | validação de formulário, filtro por tag, `rootOnly` da home |
| **Migrações** | v1→v2 (ingredient_id vira nulável) e v2→v3 (colunas de aparência) com dados reais preservados |
| **Widgets** | home (estados vazio/erro/lista), detalhe, modo cozinha, formulário, tela de pasta, busca, lixeira, galeria |
| **Engine (Dart puro)** | `Result`, `TilePattern` (cache de tiles) |

Streams do Drift + `pumpAndSettle` sob *fake async* não assentam — testes de
widget que dependem de lista do banco fazem *override* do `StreamProvider` com
`Stream.value` / `StreamController`.

### CI

[GitHub Actions](.github/workflows/ci.yml) em todo push e PR pra `main`:

1. `flutter pub get`
2. `dart run build_runner build` + `git diff --exit-code -- '*.g.dart'` (código
   gerado tem que estar commitado)
3. `flutter analyze`
4. `flutter test`
5. `flutter build apk --debug`

---

## Estado atual

O plano completo está em [`plano-app-receitas.md`](plano-app-receitas.md)
(requisitos, modelo de dados, algoritmos, design system, roadmap em quick wins).

| Bloco | Status |
|---|---|
| **A — Fundação** (tema, tipografia, azulejo, splash, schema, CI) | ✅ completo |
| **B — Primeira receita** (CRUD, form, ingredientes/passos, detalhe, modo cozinha, favoritos, lixeira, busca, tags, pastas, aparência custom) | ✅ completo *(exceto foto — movida pro bloco H)* |
| **C — Motor de ingredientes** | ⏳ próximo |
| **D — Import/export** · **E — Compras** · **F — Calendário** · **G — Acabamento** | ⬜ planejado |
| **H — Conta, sync e fotos** | ⬜ só depois de semanas de uso real |

> A foto de receita saiu do bloco B: sem armazenamento na nuvem, os arquivos
> ficam presos num aparelho só. Até lá o azulejo cobre o espaço, como o design
> já prevê.

---

## Stack

| | |
|---|---|
| **UI** | Flutter, Material 3 |
| **Estado / DI** | flutter_riverpod, riverpod_generator |
| **Navegação** | go_router |
| **Banco** | drift + sqlite3_flutter_libs, FTS5 |
| **Modelos** | freezed |
| **Cozinha** | wakelock_plus |
| **Futuro** | share_plus, file_picker, receive_sharing_intent (import/export) · pdf, printing (PDF) · table_calendar (semana) · http, html (import de URL) · image_picker, flutter_image_compress (foto) |

Licença da fonte Bricolage Grotesque (SIL OFL) em `assets/fonts/OFL.txt`.
