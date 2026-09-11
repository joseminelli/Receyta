# Receyta — Plano de Implementação

> Documento vivo. Flutter + MVVM, offline-first, com sync opcional.

---

## 1. Visão geral

App de gerenciamento de receitas pessoais com planejamento semanal e lista de compras automática.

**Nome:** Receyta. Construído a partir de *receita*, com o `y` no lugar do `i`. O brasileiro lê e pronuncia certo de primeira, e a troca de uma letra dá distintividade e registrabilidade. O `y` colorido é a marca — ele declara que a grafia é proposital, não erro.

> **Pendente:** verificar registro no INPI (classe 9), domínios `.app` e `.com.br`, e busca nas lojas da Apple e do Google antes de investir em material impresso.

**Princípios de projeto:**

- **Offline-first.** Tudo funciona sem internet. Sync é uma camada opcional por cima, não um pré-requisito.
- **Ingredientes normalizados.** É a decisão estrutural do app: sem isso, lista de compras e sugestão por similaridade não funcionam.
- **Sem catálogo pré-populado.** A base de ingredientes se constrói pelo uso, com fuzzy match e aliases.
- **Dados do usuário são portáteis.** Export/import JSON desde a primeira versão.
- **Maximalismo moderno com hierarquia.** Identidade visual forte e saturada, construída com escala tipográfica, blocos de cor e padrão geométrico — não com ornamento aplicado. O excesso cede espaço onde a informação manda (ver §9).

**Não escopo (v1):**

- Importação do Instagram (depende de LLM/scraping instável)
- Informação nutricional
- Comunidade / feed público / descoberta de receitas de terceiros

---

## 2. Requisitos funcionais

### RF-01 — Receitas

| ID | Requisito | Prioridade |
|---|---|---|
| RF-01.1 | Criar receita do zero | Must |
| RF-01.2 | Campos: nome, sobre, tempo de preparo, tempo de cozimento, rendimento (porções), imagem¹, notas | Must |
| RF-01.3 | Lista ordenada de ingredientes com quantidade, unidade e observação | Must |
| RF-01.4 | Lista ordenada de passos de preparo | Must |
| RF-01.5 | Agrupar ingredientes/passos em seções ("Para a massa", "Para o recheio") | Should |
| RF-01.6 | Editar e excluir (soft delete + lixeira de 30 dias) | Must |
| RF-01.7 | Duplicar receita | Should |
| RF-01.8 | Favoritar | Should |
| RF-01.9 | Busca por nome, ingrediente e tag | Must |
| RF-01.10 | Tags livres | Should |
| RF-01.11 | Modo cozinha: tela sempre ligada, passos grandes, timers inline | Should |
| RF-01.12 | Escalar porções (recalcula quantidades) | Could |

¹ A **imagem** ficou para o bloco H (Supabase Storage) — ver §10. A coluna
`recipes.image_path` já existe no schema; só a captura/exibição está adiada.
Personalização de **cor e textura do azulejo** por receita/pasta (schema v3) faz
as vezes de identidade visual até lá.

### RF-02 — Pastas

| ID | Requisito | Prioridade |
|---|---|---|
| RF-02.1 | Criar, renomear, excluir pastas | Must |
| RF-02.2 | Pastas aninhadas (subpastas) | Should |
| RF-02.3 | Mover receitas entre pastas | Must |
| RF-02.4 | Receita pode estar sem pasta (raiz) | Must |

### RF-03 — Ingredientes (motor de normalização)

| ID | Requisito | Prioridade |
|---|---|---|
| RF-03.1 | Parser de linha livre → quantidade + unidade + nome + qualificador | Must |
| RF-03.2 | `getOrCreate` com normalização (minúsculas, sem acento, singular, sem qualificadores) | Must |
| RF-03.3 | Fuzzy match com sugestão de confirmação ("Você quis dizer *tomate*?") | Must |
| RF-03.4 | Tabela de aliases apontando para o ingrediente canônico | Must |
| RF-03.5 | Tela de gerenciamento: mesclar, renomear, ver receitas que usam | Should |
| RF-03.6 | Autocomplete ao digitar, priorizando ingredientes já usados | Must |
| RF-03.7 | Categoria opcional por ingrediente (hortifruti, açougue, mercearia...) | Should |
| RF-03.8 | Preservar sempre o texto original digitado (`raw_text`) | Must |

### RF-04 — Calendário / planejamento

| ID | Requisito | Prioridade |
|---|---|---|
| RF-04.1 | Visão semanal e mensal | Must |
| RF-04.2 | Agendar receita em data + tipo de refeição (café/almoço/jantar/lanche) | Must |
| RF-04.3 | Mover, remover e duplicar agendamentos | Must |
| RF-04.4 | Sugestão de receitas com ingredientes em comum com o que já está na semana | Must |
| RF-04.5 | Marcar refeição como feita | Could |
| RF-04.6 | Anotação livre por dia | Could |

### RF-05 — Lista de compras

| ID | Requisito | Prioridade |
|---|---|---|
| RF-05.1 | Gerar lista a partir de receitas selecionadas | Must |
| RF-05.2 | Gerar lista a partir de um intervalo do calendário ("esta semana") | Must |
| RF-05.3 | Agregar quantidades do mesmo ingrediente com conversão de unidade | Must |
| RF-05.4 | Quando não houver conversão possível, listar as parcelas separadas | Must |
| RF-05.5 | Marcar item como comprado | Must |
| RF-05.6 | Adicionar item manual (fora de receita) | Must |
| RF-05.7 | Agrupar por categoria/corredor | Should |
| RF-05.8 | Mostrar de quais receitas veio cada item | Should |
| RF-05.9 | Múltiplas listas simultâneas | Could |
| RF-05.10 | Compartilhar lista como texto simples | Should |

### RF-06 — Import / Export

| ID | Requisito | Prioridade |
|---|---|---|
| RF-06.1 | Exportar tudo como JSON | Must |
| RF-06.2 | Exportar receita(s) individual(is) como JSON | Must |
| RF-06.3 | Importar JSON com detecção de duplicatas e escolha (substituir/duplicar/pular) | Must |
| RF-06.4 | `schemaVersion` no arquivo + migrações de import | Must |
| RF-06.5 | Abrir arquivo `.receyta` (extensão própria, JSON por dentro) compartilhado por outro app direto no app | Should |
| RF-06.6 | Exportar receita como PDF | Must |
| RF-06.7 | Exportar lista de compras como PDF | Could |
| RF-06.8 | Imagens embutidas em base64 no JSON (opcional, com aviso de tamanho) | Should |
| RF-06.9 | Importar receita de URL via JSON-LD schema.org/Recipe | Should |
| RF-06.10 | Importar via OCR de foto | Could |
| RF-06.11 | Compartilhar receita avulsa via link efêmero (token em Redis, sem conta) como alternativa ao arquivo | Should |

### RF-07 — Conta e sincronização (bloco H)

| ID | Requisito | Prioridade |
|---|---|---|
| RF-07.1 | Login (e-mail/senha + OAuth) | Should |
| RF-07.2 | Sync de receitas, pastas e calendário entre dispositivos | Should |
| RF-07.3 | Compartilhar pasta ou receita com outro usuário (leitura/edição) | Should |
| RF-07.4 | Lista de compras colaborativa em tempo real | Could |
| RF-07.5 | Resolução de conflito last-write-wins por campo, com histórico | Should |
| RF-07.6 | Uso do app 100% funcional sem conta | Must |

---

## 3. Requisitos não-funcionais

- **RNF-01** — Abertura da lista de receitas em < 500 ms com 500 receitas cadastradas.
- **RNF-02** — Todas as operações de escrita funcionam offline e são refletidas na UI imediatamente (otimista).
- **RNF-03** — Imagens armazenadas em disco, não no banco; apenas o caminho vai para o SQLite. Thumbnails gerados no cadastro.
- **RNF-04** — Suporte Android e iOS. Desktop como alvo secundário.
- **RNF-05** — Acessibilidade: escala de fonte do sistema respeitada, contraste AA, labels semânticos.
- **RNF-06** — Cobertura de testes: 100% dos ViewModels e do motor de ingredientes; widget tests nos fluxos críticos. Os blocos C1, E1 e F4 são Dart puro e devem ter teste antes da implementação.
- **RNF-07** — Migrações de banco versionadas e testadas (teste de migração N→N+1).
- **RNF-08** — Nenhum dado sai do dispositivo sem ação explícita do usuário.
- **RNF-09** — Localização em pt-BR desde o início, com estrutura pronta para outros idiomas.
- **RNF-10** — Nenhum valor visual hardcoded em widget: toda cor, raio, espaçamento e estilo de texto vem do tema (§9.5). Um lint check falha o build se encontrar `Color(0x...)` fora do arquivo de tokens.
- **RNF-11** — Todo texto sobre fundo colorido passa em contraste AA. A paleta ácida torna isso não-óbvio: lima sobre branco reprova, lima sobre preto-oliva passa.
- **RNF-12** — O layout não pode quebrar com nome de receita longo nem com fonte do sistema em 200%. Títulos display em duas linhas com `maxLines` e reticências.

---

## 4. Stack

### Núcleo

| Camada | Escolha | Por quê |
|---|---|---|
| Estado / DI | **Riverpod** | ViewModels testáveis, DI sem `context`, escopo por feature |
| Navegação | **go_router** | Deep links (necessário para compartilhamento e import de arquivo) |
| Models | **freezed** + **json_serializable** | Imutabilidade, `copyWith`, `==`, e serialização de graça — resolve o export |
| Banco local | **Drift** (SQLite) | Queries relacionais tipadas + streams reativos. Essencial para agregação e similaridade |
| Erros | **Result/Either** próprio ou `fpdart` | Repositórios não lançam exceção; devolvem resultado |

> Sobre Drift vs Isar/ObjectBox: as features centrais (agregar lista de compras, buscar receitas por ingredientes em comum, IDF) são consultas relacionais com join e group by. NoSQL exigiria fazer isso em memória em Dart.

### Bibliotecas por feature

| Necessidade | Pacote |
|---|---|
| PDF | `pdf` + `printing` |
| Compartilhar arquivo | `share_plus` |
| Escolher arquivo | `file_picker` |
| Receber arquivo compartilhado | `receive_sharing_intent` |
| Imagens | `image_picker`, `flutter_image_compress` |
| Caminhos | `path_provider`, `path` |
| Calendário | `table_calendar` |
| Import web | `http` + `html` (extrair JSON-LD) |
| OCR (bloco C) | `google_mlkit_text_recognition` |
| IDs | `uuid` |
| Datas | `intl` |
| Tela ligada (modo cozinha) | `wakelock_plus` |
| Fontes | assets locais (não `google_fonts` em runtime — evita FOUT e dependência de rede) |
| Animação de transição | `flutter_animate` ou implicit animations nativas |
| Reordenar (drag) | `ReorderableListView` nativo; `flutter_slidable` para swipe actions |

### Backend (bloco H)

- **Supabase** — Postgres + Auth + Storage + Row Level Security. RLS é o que torna "compartilhar essa pasta com fulano" viável sem escrever backend.
- **PowerSync** — se o offline-first com sync precisar ser robusto de verdade; faz a ponte Postgres ↔ SQLite local com fila de mutações.
- Alternativa mais simples: sync manual por *pull/push* com `updated_at`, aceitando last-write-wins. Suficiente para uso pessoal/familiar.

---

## 5. Arquitetura

```
View  →  ViewModel  →  Repository  →  Service (local / remoto)
                            ↓
                      Domain models
```

- **View** — só widgets. Sem regra de negócio, sem acesso a repositório.
- **ViewModel** — estado da tela, comandos, orquestração. Não conhece Flutter (nada de `BuildContext`).
- **Repository** — fonte de verdade de um agregado (receitas, listas, plano). Converte DTO ↔ domain. Decide local vs remoto.
- **Service** — acesso bruto: DAOs do Drift, cliente HTTP, sistema de arquivos.

```
lib/
  main.dart
  app/                 router, theme, providers globais, l10n
  core/
    result.dart
    extensions/
    utils/
  data/
    database/          tabelas, DAOs, migrações Drift
    dto/
    repositories/
    services/
  domain/
    models/            freezed
    engine/            parser, normalizer, matcher, aggregator, similarity
  features/
    recipes/           view/ viewmodel/
    folders/
    ingredients/
    planner/
    shopping/
    io/                import, export, pdf
    settings/
  shared/widgets/
```

O diretório `domain/engine/` é Dart puro, sem dependência de Flutter nem de Drift — 100% testável com unit tests rápidos.

**A árvore acima é o destino, não o ponto de partida.** Cada bloco cria só as pastas que de fato usa, e nenhuma pasta existe com um arquivo só — profundidade paga aluguel. Ao fim do bloco A a estrutura real é rasa:

```
lib/
  main.dart
  gallery_app.dart     entrypoint alternativo da galeria de componentes
  app_assets.dart      constantes de caminho de asset
  router.dart          go_router
  root_back_guard.dart
  theme/               tokens.dart · typography.dart · app_theme.dart
  widgets/             componentes compartilhados
```

`core/`, `data/`, `domain/` e `features/` entram quando o primeiro arquivo de cada um nasce (bloco B em diante). Imports internos usam `package:receyta/...`, então mover arquivo não quebra caminho relativo.

---

## 6. Modelo de dados

```sql
folders(
  id TEXT PK, parent_id TEXT NULL → folders.id,
  name TEXT, position INT,
  created_at, updated_at, deleted_at NULL
)

recipes(
  id TEXT PK, folder_id TEXT NULL → folders.id,
  name TEXT, about TEXT NULL,
  prep_minutes INT NULL, cook_minutes INT NULL, servings INT NULL,
  image_path TEXT NULL, source_url TEXT NULL, notes TEXT NULL,
  is_favorite BOOL,
  created_at, updated_at, deleted_at NULL
)

ingredients(
  id TEXT PK,
  display_name TEXT,
  normalized_key TEXT UNIQUE,
  category_id TEXT NULL → categories.id,
  usage_count INT
)

ingredient_aliases(
  id TEXT PK, ingredient_id TEXT → ingredients.id,
  normalized_alias TEXT UNIQUE
)

units(
  id TEXT PK, code TEXT UNIQUE, display_name TEXT,
  plural TEXT,
  kind TEXT,              -- mass | volume | count | subjective
  base_unit_id TEXT NULL, factor_to_base REAL NULL
)

recipe_ingredients(
  id TEXT PK, recipe_id TEXT → recipes.id,
  ingredient_id TEXT → ingredients.id,
  quantity REAL NULL, unit_id TEXT NULL → units.id,
  qualifier TEXT NULL,    -- "picado", "a gosto"
  raw_text TEXT,          -- sempre preservado
  group_label TEXT NULL, position INT
)

recipe_steps(
  id TEXT PK, recipe_id TEXT → recipes.id,
  text TEXT, group_label TEXT NULL, position INT
)

tags(id TEXT PK, name TEXT UNIQUE)
recipe_tags(recipe_id, tag_id)

categories(id TEXT PK, name TEXT, sort_order INT)

meal_plan_entries(
  id TEXT PK, recipe_id TEXT → recipes.id,
  date DATE, meal_type TEXT, servings_override INT NULL,
  note TEXT NULL, done BOOL,
  created_at, updated_at
)

shopping_lists(
  id TEXT PK, name TEXT, status TEXT, created_at, updated_at
)

shopping_list_items(
  id TEXT PK, list_id TEXT → shopping_lists.id,
  ingredient_id TEXT NULL → ingredients.id,
  manual_name TEXT NULL,     -- item avulso
  quantity REAL NULL, unit_id TEXT NULL,
  checked BOOL, note TEXT NULL, position INT
)

shopping_item_sources(
  item_id TEXT → shopping_list_items.id,
  recipe_id TEXT → recipes.id,
  quantity REAL NULL, unit_id TEXT NULL
)
```

**Índices:** `recipes(folder_id)`, `recipes(name)`, `recipe_ingredients(recipe_id)`, `recipe_ingredients(ingredient_id)`, `meal_plan_entries(date)`, `ingredient_aliases(normalized_alias)`.
**Busca textual:** tabela FTS5 virtual sobre `recipes(name, about, notes)`.

Todos os IDs são UUID e todas as tabelas sincronizáveis têm `updated_at` desde a v1 — evita migração dolorosa quando o sync chegar.

### Seed inicial

Apenas:
- **Unidades** (~30 em pt-BR): g, kg, ml, l, xícara, colher de sopa, colher de chá, colher de café, pitada, dente, unidade, fatia, ramo, maço, lata, pacote, a gosto...
- **Stopwords e qualificadores** para o normalizador: picado, ralado, fresco, grande, médio, pequeno, a gosto, opcional, bem, cerca de...
- **Categorias** padrão de corredor.

Nenhum ingrediente é semeado.

---

## 7. Formato de export

```json
{
  "schemaVersion": 1,
  "exportedAt": "2026-09-06T14:30:00Z",
  "app": "receitas",
  "kind": "full",
  "folders": [
    { "id": "...", "parentId": null, "name": "Massas", "position": 0 }
  ],
  "recipes": [
    {
      "id": "...",
      "folderId": "...",
      "name": "Frango ao curry",
      "about": "Rápido, para dias de semana",
      "prepMinutes": 15,
      "cookMinutes": 25,
      "servings": 4,
      "sourceUrl": null,
      "notes": "Fica melhor no dia seguinte",
      "tags": ["frango", "rápido"],
      "image": { "mimeType": "image/jpeg", "base64": "..." },
      "ingredients": [
        {
          "position": 0,
          "groupLabel": null,
          "rawText": "500g de peito de frango em cubos",
          "quantity": 500,
          "unit": "g",
          "name": "peito de frango",
          "qualifier": "em cubos"
        }
      ],
      "steps": [
        { "position": 0, "groupLabel": null, "text": "Tempere o frango..." }
      ],
      "createdAt": "...",
      "updatedAt": "..."
    }
  ]
}
```

- `kind`: `"full"` | `"recipes"` — export parcial omite `folders` e planejamento.
- Ingredientes viajam como **nome legível**, não por ID. Na importação passam pelo mesmo `getOrCreate`, então a base de destino reconcilia com o próprio catálogo.
- `rawText` é a fonte de verdade em caso de falha de parsing.
- Imagem opcional: sem ela o arquivo fica pequeno o bastante para WhatsApp.

---

## 8. Algoritmos centrais

### 8.1 Parser de ingrediente

```
"2 xícaras de farinha de trigo peneirada"
```

1. Extrai quantidade no início: inteiro, decimal (`1,5`), fração (`1/2`), fração unicode (`½`), intervalo (`2 a 3`).
2. Casa o próximo token contra a tabela de unidades (incluindo plurais e abreviações).
3. Remove conectivo (`de`, `da`, `do`).
4. Separa qualificador: após vírgula, ou tokens da lista de qualificadores no fim da string.
5. O restante é o nome → `getOrCreate`.

Se qualquer etapa falhar, salva tudo em `raw_text` com `quantity = null`. Nunca bloqueia o usuário.

### 8.2 getOrCreate

```
normalize(s):
  minúsculas → remove acentos → remove pontuação
  → remove stopwords e qualificadores → singulariza → trim
```

1. `SELECT` por `normalized_key`.
2. `SELECT` em `ingredient_aliases`.
3. Fuzzy: similaridade por trigrama ou Levenshtein normalizado ≥ 0.85 → devolve **candidato** para a UI confirmar. Confirmado, grava um alias.
4. Nada bateu → cria ingrediente novo.

Passos 1 e 2 são silenciosos. O passo 3 sempre pede confirmação — nunca funde ingredientes sem o usuário ver.

### 8.3 Similaridade entre receitas (sugestão no calendário)

Peso por IDF, recalculado sob demanda:

```
peso(i) = ln(total_receitas / (1 + receitas_que_usam_i))
```

Similaridade entre A e B:

```
sim(A,B) = Σ peso(i), i ∈ A∩B
         ────────────────────
         Σ peso(i), i ∈ A∪B
```

- Com menos de ~20 receitas na base, cai para peso uniforme (o IDF ainda não tem sinal).
- No calendário, o alvo é o **conjunto de ingredientes já agendados na semana**, não uma receita só.
- Filtro extra: penalizar receitas já agendadas nos últimos 14 dias, para não sugerir sempre a mesma coisa.
- Exibir o motivo: *"usa frango e gengibre, que você já vai comprar"*.

### 8.4 Agregação da lista de compras

Agrupa por `ingredient_id`. Dentro do grupo, por `unit.kind`:

- **Mesma dimensão** (massa, volume): converte tudo para a unidade base via `factor_to_base`, soma, e reapresenta na unidade mais legível (1200 g → 1,2 kg).
- **Contagem** (`unidade`, `dente`): soma direto.
- **Subjetivo** (`a gosto`, `pitada`): não soma, apenas marca presença.
- **Dimensões incompatíveis** no mesmo ingrediente: mantém linhas separadas ("Leite: 500 ml + 1 caixa").

Cada item guarda suas origens em `shopping_item_sources`, permitindo desfazer a inclusão de uma receita sem recalcular a lista inteira.

---

## 9. Design system

### 9.1 Direção

**Maximalismo moderno.** Densidade alta e cor saturada, mas o ornamento vem de escala tipográfica e blocos de cor — nunca de motivo aplicado, textura ou moldura.

Regras que definem a linguagem:

- **Sem bordas.** A separação é feita por bloco de cor e raio grande. Nada de contorno em card.
- **Sem sombra, sem gradiente, sem textura.** Superfícies chapadas.
- **Números são ilustração.** Tempo de cozimento, contagem de porções e índice de passo aparecem em escala enorme, sangrando na borda do bloco. O excesso vem de dado real ampliado — o que também resolve o card de receita sem foto.
- **Salto de escala extremo.** Display de 44–52px convivendo com label de 10px. É o contraste que carrega a personalidade, não a quantidade de elementos.
- **Ornamento cede à função.** Telas de consulta rápida (lista de compras, modo cozinha) são deliberadamente mais sóbrias que as de navegação.

### 9.2 Cor

Cor tem papel semântico fixo — indica **onde você está** antes de você ler o título.

| Token | Hex | Papel |
|---|---|---|
| `ink` | `#16150F` | Superfície escura, tipografia, barra de navegação |
| `inkSoft` | `#2B2A20` | Chips e superfícies elevadas sobre `ink` |
| `paper` | `#F5F2EA` | Superfície clara principal |
| `paperSoft` | `#E9E5D8` | Card neutro, chip sobre `paper` |
| `lime` | `#D6F45A` | Ação primária, estado ativo, destaque sobre `ink` |
| `coral` | `#FF5A38` | Seção **Receitas**; hero de receita |
| `coralLight` | `#FF7A5E` | Números ilustrativos sobre `coral` |
| `violetDeep` | `#6558E0` | Dias inativos e superfícies sobre `violet` |
| `violet` | `#7B6CF6` | Seção **Semana**; blocos de sugestão |
| `textMuted` | `#8A8674` | Labels e metadados sobre `paper` |
| `textBody` | `#3D3B30` | Corpo de texto sobre `paper` |

Regras de pareamento:

- `lime` **nunca** sobre `paper` — só sobre `ink`. Contraste reprova em fundo claro.
- Texto sobre `coral` ou `violet` é sempre branco puro; label secundário usa a versão clara do próprio matiz (`#FFD0C2`, `#D5CFFD`), nunca cinza.
- Máximo de **duas cores saturadas por tela**. Uma dominante (a da seção) e uma de apoio.
- Cor de seção: Receitas = `coral`, Semana = `violet`, **Compras = `ink`** — a seção escura.

**Por que Compras é escura.** Não sobrou cor: coral e violeta estão ocupados e `lime` é a cor de ação. Mais importante, é a tela usada no mercado, com uma mão só e muitas vezes em corredor mal iluminado — fundo escuro reduz ofuscamento e economiza bateria em OLED. É também a tela mais sóbria por princípio (§9.1), e escuro entrega isso naturalmente. Aqui `lime` é o progresso e o item marcado; `ink` puro é o fundo, `inkSoft` são as caixas e checkboxes vazios.

Modo escuro: inverter `ink` ↔ `paper` não funciona — a paleta já é escura por natureza. O modo escuro deve escurecer `paper` para `#1E1D16` e manter as cores saturadas com saturação reduzida em ~15%. **Decisão pendente**, não é v1.

### 9.3 Tipografia

Duas famílias, papéis rígidos.

**Display — Bricolage Grotesque (800)**
Nomes de receita, títulos de seção, números ilustrativos, quantidades de ingrediente.
`letter-spacing: -0.045em`, `line-height: 0.92`. O tracking negativo agressivo é assinatura da linguagem — sem ele o layout perde a personalidade inteira.

**Interface — sans do sistema (400 / 500)**
Corpo, labels, metadados, botões. Nunca acima de 500.

Escala:

| Papel | Tamanho | Família |
|---|---|---|
| Display XL (ilustrativo) | 86–130 | Bricolage 800 |
| Display L (título de tela) | 44–52 | Bricolage 800 |
| Display M (nome de receita) | 25 | Bricolage 800 |
| Display S (título de seção) | 22–24 | Bricolage 800 |
| Quantidade / métrica | 17–28 | Bricolage 800 |
| Corpo | 14 | Sans 400 |
| Label secundário | 11–12 | Sans 500 |
| Label caps | 10, `tracking 0.16em`, uppercase | Sans 500 |

Fontes empacotadas como asset local, não baixadas em runtime.

### 9.4 Padrão (azulejo modernista)

Referência: **Athos Bulcão**, não azulejo colonial. O azulejo entra reduzido a geometria pura — sem floral, sem borda recortada, sem moldura.

**Quatro módulos**, todos com tile de 40px:

| Módulo | Forma | Uso típico |
|---|---|---|
| `arco` | Quarto de círculo | `coral` — hero de receita, seção Receitas |
| `meiaLua` | Meias-luas alternadas | `violet` — pastas, blocos de sugestão |
| `diagonal` | Triângulos em dois tons | `ink` — cabeçalhos, superfícies escuras |
| `ponto` | Círculos em grade deslocada | `lime` — cards claros |

**Regras de aplicação:**

- **Escala grande.** Tile de 40px, nunca abaixo de 32. Padrão miúdo é o que faz o desenho voltar a parecer artesanal.
- **Tom sobre tom, contraste ~12%.** O padrão usa uma variante clara do próprio matiz do bloco. É a camada mais fraca da hierarquia — abaixo do número ilustrativo e muito abaixo do texto.
- **Máximo de dois módulos por tela.** Sempre com pelo menos um bloco chapado ou neutro de respiro.
- **Onde entra:** blocos de cor que substituem foto — hero de receita, tile de pasta, bloco de sugestão, canto do cabeçalho.
- **Onde nunca entra:** atrás de texto corrido, lista de ingredientes, barra de navegação, lista de compras, modo cozinha. Se o usuário lê linha a linha, o fundo é chapado.

**Tons de padrão** (adicionar aos tokens):

| Token | Hex | Sobre |
|---|---|---|
| `coralPattern` | `#FF7A5E` | `coral` |
| `violetPattern` | `#9A8EF9` | `violet` |
| `inkPattern` | `#2B2A20` | `ink` — primeiro tom do módulo diagonal |
| `inkPatternAlt` | `#37362A` | `ink` — segundo tom do módulo diagonal |
| `limePattern` | `#C2E33F` | `lime` |

**Consequência na hierarquia:** com o padrão ocupando a camada de textura, os números ilustrativos passam de tom sobre tom para **branco sólido**. Sem isso eles desaparecem no padrão.

**Atribuição determinística.** O módulo de cada receita vem do id, sem campo no banco:

```dart
final motif = TileMotif.values[recipe.id.hashCode.abs() % TileMotif.values.length];
```

A mesma receita mantém a estampa para sempre, e em qualquer dispositivo. Se ela ganhar foto depois, a foto simplesmente cobre o padrão.

### 9.5 Marca

**Logotipo.** Wordmark em Bricolage Grotesque 800, tracking −0.045em, com o `y` em `coral` sobre fundo escuro ou claro. Nunca reescrever o `y` em outro peso ou fonte.

**Símbolo — a bandeja.** Cloche de garçom reduzida a três formas: pegador (círculo), cúpula (meia-lua) e bandeja (barra arredondada). Dentro da cúpula, o `y` vazado.

**Ícone de app — "módulo único".** Um único quarto de círculo do módulo `arco` em escala máxima, centrado no canto inferior esquerdo com raio 78 (na grade de 100). Duas versões:

| Versão | Fundo | Azulejo | Bandeja |
|---|---|---|---|
| Coral | `coral` | `coralPattern`, no fundo | `paper`, chapada |
| Clara | `paper` | `coralPattern`, **dentro da bandeja** | `coral` |

Regra: o azulejo fica sempre sobre o coral. Quando o fundo é coral, o padrão é o fundo; quando o fundo é creme, o padrão vive dentro da bandeja.

**Empacotamento (`flutter_launcher_icons`).** A versão **Clara** é a de produção. `assets/brand/Appicon.png` (1024², composto) gera iOS — com `remove_alpha_ios` e fundo `paper` — Android legado e web. O adaptativo Android usa fundo `paper` (`#F5F2EA`) chapado + `assets/brand/AppiconForeground.png` com a bandeja inteira dentro do círculo central de ~620px (safe zone). Regenerar com `dart run flutter_launcher_icons`.

**Lockup.** A barra da bandeja se apoia na linha de base do wordmark — não no centro óptico. Assim o pegador fica na altura das maiúsculas e o descendente do `y` desce livre do outro lado, deixando as duas pontas simétricas. Altura do símbolo ≈ 0.76 do corpo do texto; vão de 0.18 do corpo.

**Tipografia em curvas.** Os SVGs de marca têm o glifo `y` convertido em path (extraído da Bricolage com `fontTools`), então não dependem da fonte instalada. Nunca distribuir arte de marca com `<text>`.

**Cuidados de forma.** O descendente do `y` não pode ser cortado pela borda da cúpula. Na grade de 100, corpo 44 e linha de base 56 mantêm a letra inteira dentro da forma.

**Licença.** Bricolage Grotesque é SIL Open Font License — confirmar antes de uso comercial no logotipo.

### 9.6 Ícones de ingrediente

Dez ícones em geometria chapada, na mesma linguagem do azulejo: círculos, arcos e formas cheias, sem contorno e sem detalhe interno. Grade de 40×40, `fill="currentColor"` para herdar a cor do tema.

`tomate` · `ovo` · `folha` · `cenoura` · `peixe` · `grao` · `cebola` · `pimenta` · `cogumelo` · `trigo`

**Teste de legibilidade obrigatório.** Quatro precisaram de refação por ambiguidade de silhueta: a cenoura lia como casquinha de sorvete, o grão como lua crescente, o trigo como trevo, e a pimenta como pera. Todo ícone novo passa pela folha de contato em 60px antes de entrar.

Uso: splash, estados vazios, categorias da lista de compras, e placeholder de ingrediente sem foto.

### 9.7 Splash screen

Animação de ~1,8s, fundo `coral`.

| Tempo | O que acontece |
|---|---|
| 0 – 0,3s | Bandeja completa entra em escala 0.86 → 1 |
| 0,3 – 1,3s | Seis ingredientes entram em arco, escalonados a cada 0,1s, e desaparecem ao alcançar a cúpula |
| 1,6 – 2,4s | Cúpula e pegador sobem e saem por cima; a barra permanece |
| 2,0 – 2,5s | Wordmark aparece no lugar da cúpula |

**Trajetória em arco:**

```dart
final t = curve.transform(controller.value);
final x = lerpDouble(startX, 0, t)!;
final y = lerpDouble(startY, endY, t)! - math.sin(t * math.pi) * peak;
```

O `sin(t * π)` é a altura do arco: vale 0 nas pontas e 1 no meio. Cada ingrediente recebe `startX`, `peak` e `delay` próprios.

**Por que o `y` vazado não vira artefato:** o fundo é coral e o furo do `y` mostra coral. Quando a cúpula sobe, o furo sobe junto, coral sobre coral. Em fundo claro apareceria um `y` fantasma subindo — por isso a splash é obrigatoriamente coral.

**Implementação (`lib/splash.dart`).** Dois `AnimationController`: `intro` (1150ms — entrada da bandeja + os seis ingredientes em arco, toca sempre) e `outro` (600ms — cúpula/pegador sobem e saem, wordmark entra). Start quente ≈ 1,75s, dentro do orçamento de `SplashTimings.budget` (1,8s). Zero dependência: a bandeja é geometria chapada (`CustomPainter`) — pegador (círculo), cúpula (meia-lua), barra (stadium) em `paper` sobre `coral`; os ingredientes são seis formas simples na mesma linguagem. Trocar por `flutter_svg` + os ícones da §9.6 quando eles existirem.

**Regra de produto:** a splash não pode atrasar a abertura. A `intro` roda em paralelo ao `appBootstrapProvider` (`lib/bootstrap.dart` — Drift no A7); a `outro` só toca quando o app está pronto. Se o bootstrap demora, a splash segura na última frame da `intro` até resolver — nunca trava, nunca corta a `outro`. A splash nativa (`flutter_native_splash`) usa o mesmo `coral`, então nativo → Flutter é invisível.

### 9.8 Forma e espaço

- **Raios:** card grande 20px · card pequeno 16–18px · sheet 26px · chip, botão e barra de navegação 99px (pílula total).
- **Sem meio-termo:** ou é pílula, ou é raio grande. Nada de 4–8px.
- **Margem lateral padrão:** 18px.
- **Barra de navegação flutuante** em pílula `ink`, item ativo em `lime`, inativos só ícone.
- **Sangramento:** números ilustrativos podem ultrapassar a borda do bloco pai (`overflow: hidden` no pai). É intencional e recorrente.
- **Sheet de conteúdo** sobe 18px sobre o hero, com raio no topo.

### 9.9 Implementação no Flutter

```
lib/theme/
  tokens.dart       AppColors, AppRadii, AppSpacing — únicas constantes de cor do projeto
  typography.dart   AppTextStyles (display*, body*, label*)
  app_theme.dart    ThemeData montado a partir dos tokens
```

- Cores via `ThemeExtension<AppColors>` para acesso tipado: `context.colors.lime`.
- Assets de marca e ingredientes referenciados por constantes em `AppAssets`, nunca por string solta.
- `TextTheme` com os papéis mapeados; nunca `TextStyle` inline em tela.
- Componentes compartilhados em `lib/widgets/`: `RecipeCard`, `FolderTile`, `MetricStat`, `SectionHeader`, `PillButton`, `PillNavBar`, `HeroNumber`, `IngredientRow`, `SuggestionBlock`, `TilePattern`.
- `HeroNumber` encapsula o padrão do número sangrado: recebe valor, cor e canto de ancoragem.
- `TilePattern(motif:, background:, patternColor:, patternColorAlt:, tile: 40)` desenha o azulejo via `CustomPainter`. Um único tile é rasterizado com `PictureRecorder.toImageSync` e cacheado por `(módulo, cor, cor alt, tile, dpr)`; o painter pinta o bloco chapado + uma `drawRect` com `ImageShader(TileMode.repeated)`. Custo por card: uma `drawRect`, não um path por pixel. O `diagonal` é o único que usa o segundo tom (`inkPatternAlt`). Módulo por receita: `tileMotifForId(recipe.id)`.
- Widgetbook (ou galeria própria) para revisar todos os componentes fora do app. O benchmark de scroll do A4 vive lá: `TilePattern — benchmark`, 60 cards, rodar em `--profile`.

**Assets de marca:**

```
assets/
  brand/       icone (coral, claro) · simbolo · lockup horizontal e vertical
  ingredients/ 10 svg com fill=currentColor
  fonts/       Bricolage Grotesque 800 (display) — asset local, não runtime
```

### 9.10 Telas ainda não desenhadas

Criar/editar receita · importar (arquivo, URL, foto) · modo cozinha · conflitos de importação · mesclagem de ingredientes · onboarding · estados vazios · configurações.

O modo cozinha pode reaproveitar a superfície escura já definida para Compras, em vez de criar um terceiro tema.

---

## 10. Roadmap em quick wins

Cada entrega abaixo cabe em meio dia a dois dias, é testável isoladamente e deixa o app em estado funcional. A ordem importa, mas os blocos são independentes o bastante para você trocar a sequência a partir do bloco D.

**Marcos de valor** são as entregas em que o app passa a fazer algo que antes não fazia — são elas que mantêm o projeto vivo. Estão marcadas com 🎯.

Esforço em dias de trabalho focado.

---

### Status de implementação

*Atualizado conforme o código; a barra está no fim do bloco B.*

- **Bloco A (A1–A8)** — ✅ completo e commitado.
- **Bloco B** — ✅ completo, **exceto imagem** (B7 foi movida para o bloco H,
  ver abaixo). Entregues: B1, B2, B3, B4, B5, B6, B8, B9, B10.
  - **Tags** (§RF-01.10) e o **modo cozinha mínimo** (fatia do G1: wakelock +
    passos grandes em lista + ingredientes recolhíveis, com aviso visível de
    "tela acesa") entraram junto neste bloco.
  - **B5** ganhou separadores de seção em ingredientes e passos (§RF-01.4):
    "Para a massa" etc. viram `group_label` das linhas seguintes.
  - **B10** foi além do previsto: personalizar **cor e textura do azulejo** de
    cada receita e pasta (schema **v3**, colunas `tile_color`/`tile_motif`
    nuláveis, editável pelo menu ⋯); **arrastar e soltar** receita→pasta,
    pasta→pasta e "tirar da pasta" (e arrastar receita até um alvo circular
    pra mandar pra lixeira); menu `+` expansível ("Nova receita" / "Nova
    pasta"); a home sem filtro mostra só a raiz; "Recentes" (receitas) e
    "Pastas" da home viram prateleiras por **uso recente** (MRU) capadas em 7,
    com "Ver todas" pra lista completa (schema **v4**, coluna
    `last_opened_at` nas duas tabelas).
- **Bloco C em diante** — não começado. Próximo passo real: **usar o app com
  receitas de verdade por uma semana** (ver aviso ao fim do bloco B), depois C1.

---

### Bloco A — Fundação
*Nada disso aparece para o usuário, mas tudo depois depende. ~5 dias.*

| ID | Entrega | Esforço | Pronto quando |
|---|---|---|---|
| A1 | Esqueleto: projeto, Riverpod, go_router, l10n pt-BR | 0,5 | App abre numa tela vazia e navega entre duas rotas |
| A2 | Tokens, tipografia, `ThemeData`, Bricolage como asset local | 1 | Nenhuma cor ou `TextStyle` fora de `lib/theme/` |
| A3 | Galeria de componentes com `SectionHeader`, `PillButton`, `PillNavBar`, `MetricStat`, `HeroNumber` | 0,5 | Galeria navegável fora do app |
| A4 | `TilePattern` com os quatro módulos + benchmark de scroll | 1 | 60 cards com padrão rolam a 60fps |
| A5 | Ícone de app (duas versões, todos os tamanhos) e adaptativo Android | 0,5 | Ícone correto nas duas plataformas |
| A6 | Splash animada, cortando assim que o banco responde | 1 | Abertura nunca passa de 1,8s |
| A7 | Drift com schema v1 + seed de unidades, qualificadores e categorias | 1 | Banco criado, seed conferido em teste |
| A8 | CI rodando testes + teste de migração v1→v2 | 0,5 | Pipeline verde e bloqueando merge |

---

### Bloco B — A primeira receita
*Aqui o app vira útil. ~6,5 dias.*

| ID | Entrega | Esforço | Pronto quando |
|---|---|---|---|
| B1 | Model `Recipe` em freezed + DAO + repositório | 0,5 | Testes de repositório passando |
| B2 | Tela de lista com dados falsos, só UI | 1 | Layout bate com o desenho aprovado |
| B3 | 🎯 Lista lendo do Drift + criar receita só com nome | 0,5 | Você cadastra e reencontra uma receita real |
| B4 | Formulário completo: sobre, tempos, porções, notas | 1 | Todos os campos persistem e voltam |
| B5 | Ingredientes e passos como texto livre, gravando `raw_text`, com separadores de seção | 1 | Listas reordenáveis, nada se perde |
| B6 | Tela de detalhe | 1 | 🎯 Dá para cozinhar lendo pelo app |
| B8 | Favoritar, soft delete e lixeira de 30 dias | 0,5 | Nada é apagado de verdade antes do prazo |
| B9 | Busca FTS por nome, sobre e notas | 0,5 | Busca responde abaixo de 100ms com 200 receitas |
| B10 | Pastas: criar, renomear, mover, aninhar | 1 | 🎯 20 receitas reais organizadas |

> **B7 (imagem) saiu daqui.** Foto de receita só compensa com armazenamento na
> nuvem: sem Storage, os arquivos ficam presos num aparelho só e ainda exigem
> compressão, thumbnail e faxina de órfãos. Foi movida para o **bloco H**, junto
> do Supabase. Até lá o azulejo (§9.4) cobre o espaço da foto, como o §9 já prevê.

> **Pare aqui e use o app por uma semana.** As entregas seguintes ficam muito melhores com receitas reais no banco — o parser precisa de exemplos verdadeiros, e o IDF não funciona com base vazia.

---

### Bloco C — Ingredientes viram dados
*O bloco que destrava lista de compras e sugestão. ~7 dias.*

| ID | Entrega | Esforço | Pronto quando |
|---|---|---|---|
| C1 | Parser de quantidade e unidade, Dart puro | 1 | 50 linhas reais parseiam com ≥90% de acerto |
| C2 | Normalizador + `getOrCreate` com match exato e aliases | 0,5 | "tomates" e "tomate" viram o mesmo id |
| C3 | 🎯 Autocomplete de ingrediente no formulário | 0,5 | Cadastrar receita fica mais rápido que antes |
| C4 | Fuzzy match com confirmação do usuário | 1 | Nunca funde sozinho; sempre pergunta |
| C5 | Migração que reprocessa os `raw_text` do bloco B | 0,5 | Receitas antigas ganham ingredientes normalizados |
| C6 | Tela de gerenciar e mesclar ingredientes | 1 | Duplicata detectada some em dois toques |
| C7 | Import de URL por JSON-LD (RF-06.9) | 1 | 8 de 10 sites de receita importam limpo |
| C8 | Import por foto: câmera/galeria + OCR on-device, auto-preenche o formulário sem salvar a imagem (RF-06.10) | 1,5 | Foto de uma receita impressa preenche nome/ingredientes/passos pra revisão; nenhum arquivo de imagem fica gravado |

> **C7 e C8 são duas entradas para o mesmo formulário.** Ambas rodam o texto
> extraído (JSON-LD ou OCR) pelo parser do C1 e o normalizador do C2 — o
> usuário sempre revisa antes de salvar, igual a digitar manualmente. C8 não
> depende do bloco H: a imagem só existe em memória durante o reconhecimento
> (`google_mlkit_text_recognition`, local) e é descartada depois; guardar a
> foto da receita em si é o H0, um recurso diferente.

---

### Bloco D — Os dados saem e entram
*Independente dos blocos E e F. ~6 dias.*

| ID | Entrega | Esforço | Pronto quando |
|---|---|---|---|
| D1 | 🎯 Export de uma receita como `.receyta` (JSON) + share sheet | 0,5 | Você manda uma receita pelo WhatsApp |
| D2 | Export completo com pastas e `schemaVersion` | 0,5 | Arquivo serve como backup manual |
| D3 | Import com `file_picker` + reconciliação de ingredientes | 1 | Importar em outro device reproduz a base |
| D4 | Tela de conflitos: substituir, duplicar ou pular | 0,5 | Reimportar o mesmo arquivo não gera lixo |
| D5 | `receive_sharing_intent`: abrir `.receyta` pelo sistema | 0,5 | Tocar no anexo abre o Receyta |
| D6 | 🎯 PDF da receita | 1 | Impressão sai legível em A4 |
| D7 | Link efêmero: function + Redis (`SET share:<token> <json> EX 3600`, ou pilha de N por dispositivo) | 1 | Token expira/estoura sem faxina manual |
| D8 | Deep link (App Links/Universal Links) resolvendo o token e abrindo direto na tela de import | 1 | Tocar no link no WhatsApp abre o Receyta com a receita pronta pra importar |

> **Dois mecanismos de compartilhar uma receita, de propósito (não é
> duplicação).** `.receyta` (arquivo, D1/D5) e **link efêmero** (D7/D8) resolvem
> problemas diferentes e usam o mesmo corpo JSON do §7 por baixo — não são
> dois caminhos de código, é o mesmo serializer com dois transportes.
>
> - **Link é o padrão** no botão "Compartilhar": abre o Receyta sozinho nas
>   duas plataformas via App Links/Universal Links (sem a ambiguidade de
>   "abrir com" que um arquivo tem no iOS) e ainda gera preview bonito no
>   WhatsApp. Custo: exige internet dos dois lados antes do token expirar, e
>   depende de uma function pequena + Redis no ar (Upstash free tier serve;
>   não precisa de conta de usuário, só um id anônimo de dispositivo pra
>   aplicar o limite de pilha por usuário).
> - **Arquivo continua existindo** como opção secundária ("compartilhar como
>   arquivo") e é a única via para **export completo** (D2 — múltiplas
>   receitas/backup): isso não cabe no modelo de TTL do Redis, e precisa
>   funcionar mesmo sem servidor nenhum no ar (ex.: mandar por Bluetooth/e-mail,
>   ou guardar como backup permanente numa nuvem própria).
> - Nenhum dos dois usa o Postgres do bloco H — ele fica reservado para o que
>   de fato precisa persistir e sincronizar (calendário, lista de compras
>   compartilhada, RF-07), evitando que compartilhar receitas avulsas lote o
>   tier free do banco relacional.

---

### Bloco E — Lista de compras
*~4 dias.*

| ID | Entrega | Esforço | Pronto quando |
|---|---|---|---|
| E1 | Tabela de conversão + agregador, Dart puro | 1 | 500g + 800g vira 1,3kg; incompatíveis ficam separados |
| E2 | Gerar lista a partir de receitas selecionadas | 1 | Lista sai correta de 6 receitas |
| E3 | 🎯 Tela escura de compras + marcar item | 1 | Uma compra real feita só pelo app |
| E4 | Agrupar por categoria e adicionar item manual | 0,5 | Ordem bate com o corredor do mercado |
| E5 | Rastreio de origem + export em texto | 0,5 | Item mostra de quais receitas veio |

---

### Bloco F — Calendário e sugestões
*~3,5 dias.*

| ID | Entrega | Esforço | Pronto quando |
|---|---|---|---|
| F1 | Tela semanal + agendar receita por dia e refeição | 1 | Semana inteira planejada em 2 minutos |
| F2 | Mover, remover e duplicar agendamento | 0,5 | Arrastar entre dias funciona |
| F3 | 🎯 Gerar lista de compras a partir da semana | 0,5 | Fecha o ciclo planejar → comprar → cozinhar |
| F4 | Similaridade por IDF, Dart puro | 1 | Frango puxa mais que sal, sem configuração |
| F5 | Bloco de sugestão com o motivo explicado | 0,5 | Sugestão diz *por que* sugeriu |

---

### Bloco G — Acabamento
*Cada item é independente; pegue por ordem de incômodo. ~2,5 dias.*

| ID | Entrega | Esforço | Pronto quando |
|---|---|---|---|
| G1 | Modo cozinha: wakelock, passos grandes, timers | 1 | Cozinhar sem tocar na tela com a mão suja |
| G2 | Escalar porções | 0,5 | Dobrar a receita recalcula tudo |
| G3 | Estados vazios e onboarding | 1 | App recém-instalado não parece quebrado |

---

### Bloco H — Conta, sync e fotos
*Só depois de usar o app no dia a dia por algumas semanas. 3+ semanas.*

Supabase, auth, RLS, espelhamento do schema, fila de mutações offline, compartilhamento de pasta, lista colaborativa.

| ID | Entrega | Esforço | Pronto quando |
|---|---|---|---|
| H0 | Imagem de receita (ex-B7): câmera e galeria, compressão, thumbnail, **Supabase Storage** com caminho local como cache | 1 | Foto tirada num aparelho aparece no outro; some da UI mas o arquivo local vira cache |

Não comece este bloco antes de responder duas coisas com uso real: você de fato precisa de sync, ou export/import já resolve? E quantas pessoas vão compartilhar de verdade? (Se a resposta for "só quero as fotos", dá pra fazer o H0 sozinho com Storage, sem o resto do sync.)

---

### Resumo

| Bloco | Esforço | Entrega o quê |
|---|---|---|
| A — Fundação | 5 d | Nada visível, tudo depende |
| B — Primeira receita | 6,5 d | **App já substitui o caderno** |
| C — Ingredientes | 7 d | Destrava compras e sugestão; import por URL e foto |
| D — Import/export | 6 d | Compartilhar (arquivo ou link) e fazer backup |
| E — Compras | 4 d | **Substitui a lista do mercado** |
| F — Calendário | 3,5 d | **Fecha o ciclo da semana** |
| G — Acabamento | 2,5 d | Tira as arestas |
| **Até G** | **34,5 d** | ~7 semanas de trabalho focado |

Fora dessa conta: **bloco H** (conta, sync e a foto de receita ex-B7), que só
entra depois de semanas de uso real.

Três momentos em que o app fica bom o bastante para parar: **fim do bloco B** (caderno de receitas digital), **fim do bloco E** (receitas + compras) e **fim do bloco F** (o produto completo). Qualquer um deles é um lugar legítimo para parar e usar por um mês antes de continuar.

---

## 11. Riscos e decisões em aberto

| Risco | Mitigação |
|---|---|
| Parser de ingrediente falha em casos reais | `raw_text` sempre preservado; UI permite corrigir manualmente; suíte de teste alimentada por casos reais |
| Fuzzy match funde ingredientes distintos ("leite" / "leite de coco") | Nunca funde automaticamente; qualificadores como "de coco" contam como parte do nome, não como qualificador |
| Base de ingredientes vira lixo com duplicatas | Tela de mesclagem + `usage_count` para destacar órfãos |
| Sync com conflito corrompe dados | Só depois da v1; `updated_at` por registro desde já; export JSON funciona como backup manual |
| Import de URL quebra por mudança de site | JSON-LD é padrão estável; falha degrada para "colar texto manualmente" |
| OCR erra em foto de baixa qualidade, letra à mão ou fonte estilizada | Preenche só o que reconhece; usuário sempre revisa antes de salvar, como digitação manual; imagem nunca é gravada, só o texto extraído |
| Link efêmero de receita (D7/D8) depende de backend no ar antes do bloco H | Falha vira "compartilhar como arquivo" (`.receyta`, offline, sem prazo); TTL curto (1h) ou pilha por dispositivo limita custo/abuso do Redis sem precisar de conta |
| Tipografia display quebra com nome de receita longo | `maxLines: 2` com reticências; testar com "Estrogonofe de frango com arroz sete grãos" |
| Paleta ácida reprova em contraste | Regras de pareamento fixas na §9.2; teste automatizado de contraste sobre os tokens |
| Maximalismo cansa no uso diário | Telas de consulta (compras, modo cozinha) já nascem sóbrias; validar depois de 2 semanas de uso real |
| Padrão de azulejo pesa no scroll | `CustomPainter` com cache por (módulo, cor); medir com 60 cards ainda no A4 |
| Azulejo puxa o design de volta ao artesanal | Regras fixas na §9.4: tile ≥ 32px, contraste ~12%, máx. 2 módulos por tela |
| Escala tipográfica do sistema em 200% estoura o layout | Display com escala limitada; corpo acompanha o sistema integralmente |
| Splash atrasa a abertura do app | Animação corre em paralelo à inicialização do Drift e é cortada assim que o banco responde |
| Ícone de ingrediente ambíguo | Folha de contato em 60px obrigatória antes de aprovar qualquer ícone novo |
| Nome "Receyta" já registrado | Verificar INPI, domínios e lojas antes de material impresso; o design não muda se o nome mudar |

**Decisões pendentes:**

- Sync via PowerSync (robusto, mais dependências) ou pull/push manual com `updated_at` (simples, LWW)?
- Escala de porções recalcula e grava, ou é só visualização?
- Compartilhamento de pasta: permissão por pasta ou por receita?
- Modo escuro entra em qual bloco? A paleta não inverte trivialmente, e Compras já é escura.
- Card de receita: padronizar formato ou manter grid assimétrico (um grande + dois pequenos)?
- Modo cozinha reaproveita a superfície escura de Compras, ou precisa de contraste ainda maior?
- Quatro módulos de azulejo bastam, ou a repetição fica visível com 80+ receitas na grade?
- Dez ícones de ingrediente cobrem as categorias, ou faltam laticínio e massa?
- A splash roda em toda abertura ou só na primeira do dia?
