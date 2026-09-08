# Revisão — Bloco A (Fundação)

Estado em 2026-09-08. O Bloco A do roadmap (`plano-app-receitas.md` §10) está
**completo**: A1 a A8. Nada disso aparece para o usuário final, mas tudo que vem
depois depende desta base.

Este documento cobre em detalhe o que foi feito nas duas últimas entregas
(**A7** e **A8**), que montaram a camada de dados, e recapitula A1–A6.

---

## 1. Onde o app está

| Bloco | Entrega | Estado |
|---|---|---|
| A1 | Esqueleto: Flutter + Riverpod + go_router + l10n pt-BR | ✅ |
| A2 | Tokens, tipografia, `ThemeData`, Bricolage como asset local | ✅ |
| A3 | Galeria de componentes (`SectionHeader`, `PillButton`, `PillNavBar`, `MetricStat`, `HeroNumber`) | ✅ |
| A4 | `TilePattern` (4 módulos) + benchmark de scroll | ✅ |
| A5 | Ícone de app (iOS + adaptativo Android) e splash nativa | ✅ |
| A6 | Splash animada, cortando quando o banco responde | ✅ |
| **A7** | **Drift: schema v1 + seed de unidades, qualificadores e categorias** | ✅ |
| **A8** | **CI rodando testes + harness de migração de schema** | ✅ |

O que o app faz hoje: abre, mostra a splash animada sobre coral, cria e semeia
o banco local na primeira execução, e navega para uma home placeholder. Ainda
**não dá para cadastrar uma receita** — isso é o Bloco B.

```
Fluxo de abertura:
  splash nativa (coral)  →  Splash animada (Flutter)
                                   │  em paralelo
                                   ▼
                          appBootstrapProvider
                                   │  abre o Drift, roda migração, confere seed
                                   ▼
                          home  (quando o banco responde)
```

---

## 2. A7 — Camada de dados (Drift)

### O que foi feito

Um banco SQLite local, tipado, com o **schema v1 completo** do §6 do plano.

**Arquivos novos — `lib/data/database/`**

| Arquivo | Papel |
|---|---|
| `tables.dart` | 15 tabelas como classes Dart. Chaves estrangeiras, defaults, `updated_at` em tudo que vai sincronizar um dia. |
| `seed_data.dart` | Listas `const` em Dart puro: unidades, categorias, vocabulário do normalizador. Sem dependência de Drift. |
| `connection.dart` | Abre `receyta.sqlite` no diretório de documentos do app. Abertura preguiçosa (só na 1ª query). |
| `app_database.dart` | A classe `AppDatabase`: versão do schema, estratégia de migração, criação de índices/FTS/triggers, e o seed. |
| `app_database.g.dart` | Código gerado pelo `build_runner` (não editar à mão). |
| `database_provider.dart` | `databaseProvider` — instância única do banco, fechada junto com o app. |

**Alterado**
- `lib/bootstrap.dart` — o `appBootstrapProvider` (que a splash espera) agora
  abre o Drift e confere o seed, em vez de resolver na hora.

**As 15 tabelas:** `folders`, `recipes`, `categories`, `ingredients`,
`ingredient_aliases`, `units`, `recipe_ingredients`, `recipe_steps`, `tags`,
`recipe_tags`, `meal_plan_entries`, `shopping_lists`, `shopping_list_items`,
`shopping_item_sources`, `normalizer_terms`.

Mais: os **6 índices** do §6, uma tabela virtual **FTS5** sobre `recipes` (busca
textual por nome/sobre/notas) mantida em sincronia por 3 triggers, e
`PRAGMA foreign_keys = ON`.

### O seed (dados que já nascem no banco)

| Conjunto | Qtd | Conteúdo |
|---|---|---|
| **Unidades** | 32 | massa (g, kg, mg — convertem para `g`), volume (ml, l, xícara, colheres, copo — convertem para `ml`), contagem (unidade, dente, fatia, lata, maço…), subjetivas (a gosto, pitada, quanto baste) |
| **Categorias de corredor** | 15 | Hortifrúti → Açougue → Peixaria → … → Outros, na ordem de percurso do mercado |
| **Termos do normalizador** | 117 | 30 stopwords (`de`, `da`, `com`, `sem`…) + 87 qualificadores (`picado`, `ralado`, `em cubos`, `a gosto`… com variações de gênero/número) |

Nenhum **ingrediente** é semeado — eles nascem conforme você cadastra receitas.

### Pra que foi feito

- **As features centrais do app são consultas relacionais.** Agregar uma lista
  de compras de 6 receitas, achar receitas com ingredientes em comum, calcular
  IDF para sugestão no calendário — tudo isso é `JOIN` + `GROUP BY`. Um banco
  NoSQL obrigaria a fazer em memória, em Dart.
- **O schema já nasce completo (v1 = §6 inteiro).** Assim os blocos B, C, E e F
  não precisam de migração de estrutura — só de dados. Todas as tabelas
  sincronizáveis já têm `updated_at`, o que evita uma migração dolorosa quando
  o sync (fora do v1) chegar.
- **O seed é a matéria-prima do parser (§8).** Quando o Bloco C for ler
  "2 xícaras de farinha de trigo peneirada", ele casa "xícaras" contra a tabela
  `units` e tira "peneirada" via `normalizer_terms`. Esses dados precisam
  existir antes.
- **`normalizer_terms` é uma extensão deliberada** do modelo do §6 (que não
  previa a tabela). Foi decisão tomada com você: fica no banco, semeado na v1,
  mas o motor de normalização (Dart puro, sem Drift) vai receber as listas por
  parâmetro — continua testável isoladamente.

### Como impacta o app

- **Primeira abertura:** o banco é criado e semeado. A splash segura a última
  frame da animação até isso terminar (rápido — bem abaixo do orçamento de
  1,8s). Aberturas seguintes abrem o arquivo direto.
- **IDs estáveis:** linhas de seed usam slugs determinísticos (`g`, `xicara`,
  `cat_hortifruti`), não UUID aleatório. Idempotente, e não quebra quando o
  sync entre dispositivos existir.
- **Segurança de tipo:** consultas ao banco são checadas em tempo de
  compilação. Um `SELECT` com coluna errada não compila.
- **Nada de dados de usuário ainda** — o banco está vazio de receitas. O
  impacto visível é só a splash esperar ~alguns ms a mais na 1ª vez.

### Detalhe técnico que vale registrar

A coluna que o §6 chama de `recipe_steps.text` virou **`instruction`**: o nome
`text` colide com o construtor de coluna do Drift e quebra o gerador de código.

---

## 3. A8 — CI e harness de migração

### O que foi feito

**CI — `.github/workflows/ci.yml`** — roda em todo PR e push para `main`:

- **job `verify`**: instala Flutter 3.27.1 → `pub get` → roda o codegen → checa
  que o `.g.dart` commitado está atualizado → `flutter analyze` → `flutter test`
- **job `build`**: `flutter build apk --debug`

**Harness de migração**

| Arquivo | Papel |
|---|---|
| `drift_schema/drift_schema_v1.json` | Fotografia do schema v1, versionada no git. Baseline para comparar as próximas versões. |
| `test/data/database/generated/` | Helpers de verificação gerados pelo `drift_dev`. |
| `test/data/database/schema_test.dart` | 2 testes: (a) o `onCreate` constrói todas as tabelas declaradas; (b) o schema do código bate com o snapshot v1. |

**Detalhe de teste:** `flutter test` roda na Dart VM, sem plugins nativos, então
a `sqlite3` que o app usa (via `sqlite3_flutter_libs`) não existe.
`test/flutter_test_config.dart` resolve apontando para uma `sqlite3` do sistema
(`winsqlite3.dll` no Windows, `libsqlite3` no Linux — o CI instala).

### Pra que foi feito

- **Bloqueio de merge.** Ninguém consegue quebrar a compilação, os lints ou os
  testes sem o CI apontar. (Falta você marcar os dois jobs como *required* em
  Settings → Branches no GitHub — isso não dá para fazer por código.)
- **Migração é a parte mais perigosa de um banco local.** Quando o Bloco C
  mudar o schema (reprocessar os `raw_text`), o teste v(N-1)→vN garante que
  nenhuma receita real se perde no caminho. O A8 monta essa infraestrutura
  **antes** de ela ser necessária, com o v1 já fotografado.
- **`schema_test.dart` é uma trava.** Se alguém mudar `tables.dart` sem
  atualizar o snapshot, o CI fica vermelho — evita o schema em disco divergir
  silenciosamente do que o código espera.

### Como impacta o app

- Zero impacto em runtime. É tudo infraestrutura de desenvolvimento.
- `onUpgrade` está vazio de propósito: v1 é o baseline, não há de onde migrar
  ainda. O primeiro passo real de migração entra no Bloco C.

---

## 4. Ajustes da splash (nesta rodada)

O fundo animado da splash (shader `shaders/splash_background.frag`) estava com o
padrão forte demais competindo com a bandeja. Foi suavizado para tom sobre tom:
menos contraste entre os tons de coral, anéis concêntricos mais largos, fluxo
mais lento, e o centro (onde fica a bandeja) mais calmo que as bordas.

**Ainda em calibragem** — precisa de mais um olhar no device. Os parafusos de
ajuste estão comentados no `.frag` (intensidade da variação) e no `splash.dart`
(velocidade).

---

## 5. Convenção adotada

**Comentários só de header, curtos.** Nada de comentário explicando uma linha no
meio do código, nada de divisórias tipo `// --- seção ---`. Os arquivos novos
(A7/A8) seguem isso. O código legado dos blocos A1–A6 (`splash.dart`,
`gallery_app.dart`) continua comentado como estava — não foi mexido.

---

## 6. Verificação

| Check | Resultado |
|---|---|
| `flutter analyze` | limpo |
| `flutter test` | **32 testes** verdes |
| `flutter build apk --debug` | ✅ `app-debug.apk` |

Cobertura de teste da camada de dados: criação do schema, todas as tabelas
presentes, FK sendo respeitada, seed de unidades (contagem, kinds, conversões),
categorias (ordem sem buracos), normalizador (termos conhecidos, sem
duplicata), idempotência do seed, FTS5 (busca por nome/sobre, acompanha update,
some no delete), e o wiring `appBootstrapProvider → Drift → seed`.

---

## 7. Próximo passo

**Bloco B — A primeira receita.** Começa em **B1**: model `Recipe` em freezed +
DAO + repositório, lendo do banco que o A7 criou. É onde o app começa a ser
útil de verdade.
