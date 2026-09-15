# Importação de receitas (link e foto/OCR)

> Parte 7 de 7 do guia técnico. [Índice](../arquitetura-e-fluxo.md) ·
> anterior: [O motor de ingredientes](06-motor-de-ingredientes.md). Cobre
> C7 (RF-06.9, import de URL) e C8 (RF-06.10, import por foto/OCR).

Regra de produto que vale pros dois: **import nunca salva sozinho.** Cada
um extrai um `ImportedRecipe` (`lib/domain/engine/recipe_import.dart` —
nome, sobre, tempos, porções, listas de linha crua de ingrediente/passo,
`sourceUrl?`) e abre `/recipe/new` com ele como `extra`
(`RecipeFormPage(draft: state.extra as ImportedRecipe?)` em `router.dart`).
O usuário sempre revisa e confirma no formulário — exatamente como se
tivesse digitado à mão. É por isso que os dois reaproveitam **o mesmo**
motor de ingredientes (parser C1 + normalizador C2, ver
[arquivo anterior](06-motor-de-ingredientes.md)): as linhas cruas do import
só passam pelo parser na hora de salvar, igual à digitação manual.

```
   C7 (URL)                          C8 (foto)
extractRecipeFromHtml()           parseOcrLinesMulti()
       │                                 │
       └──────────► ImportedRecipe ◄─────┘
                          │
              context.push('/recipe/new', extra: recipe)
                          │
              RecipeFormPage(draft: recipe) — pré-preenche, nunca salva
                          │
              usuário revisa e toca "Salvar" → RecipeRepository.saveDetail
              (parser C1 + getOrCreate C2 rodam aqui, não antes)
```

---

## C7 — import de URL via JSON-LD

`lib/domain/engine/recipe_import.dart`: `extractRecipeFromHtml(html, {sourceUrl})`
procura um `<script type="application/ld+json">` com `@type: "Recipe"` —
direto, dentro de `@graph`, ou dentro de um array na raiz (`_findRecipeNode`,
recursivo) — e mapeia os campos do schema.org/Recipe pros do `ImportedRecipe`:

- `prepTime`/`cookTime` (duração ISO 8601, `"PT30M"`) → minutos
  (`_parseIsoDurationMinutes`, regex `^P(?:\d+D)?T?(?:(\d+)H)?(?:(\d+)M)?`).
- `recipeYield`/`yield` (string, número ou lista) → inteiro (`_parseServings`,
  extrai o primeiro número da string).
- `recipeIngredient`/`ingredients` → lista de linha crua (`_stringList`).
- `recipeInstructions` → lista de passo, achatando `HowToStep`/`HowToSection`
  aninhada (`_extractSteps`, recursivo — uma seção como
  `{"@type":"HowToSection","itemListElement":[...]}` vira os passos de dentro
  dela, em ordem).

`lib/data/services/recipe_import_service.dart`: `RecipeImportService.importFromUrl`
busca via `http`, com **User-Agent de navegador** (vários sites bloqueiam
requisição sem UA reconhecível) e timeout de 15s; devolve `Result<ImportedRecipe>`
(`NetworkFailure`/`ValidationFailure`). Ponto que rendeu bug real, corrigido:
`response.body` usa o charset do `Content-Type`, e cai pro `latin1` quando o
site não declara um (comum) — mesmo a página sendo UTF-8 de verdade, gerando
mojibake ("TÃ©cnica" em vez de "Técnica"). Corrigido decodificando sempre
`utf8.decode(response.bodyBytes, allowMalformed: true)`, ignorando o header.

### Tag automática do site

`siteTagFromUrl(sourceUrl)`, no mesmo arquivo do engine, extrai o nome do
site do host pra virar tag automática (`"tudogostoso.com.br"` → "Tudogostoso",
`"receitas.globo.com"` → "Globo"). Trata sufixo de domínio de duas partes
(`_twoPartSuffixes`, lista curta tipo `com.br`/`co.uk` — **não** é uma lista
pública de sufixos completa, só cobre os TLDs comuns entre sites de receita)
pra não confundir o TLD com o nome do site. Aplicada em `_tags` do formulário
só quando a receita vem de um `draft`.

### Cabeçalho de seção nas listas ("Para o arroz de sushi:")

Alguns sites embutem um cabeçalho de seção como se fosse item de ingrediente.
`_headingAwareDraftLines` (em `recipe_form_page.dart`) detecta linha curta
(≤60 chars) terminando em `:` e vira `group` das linhas seguintes — mesmo
separador que o usuário cria à mão (§RF-01.4/01.5), aplicado tanto em
ingredientes quanto em passos.

### Ponto de entrada

`ExpandingCreateMenu` (o `+` do cabeçalho da home) → opção "Importar de
link" → `recipe_import_flow.dart` (`importRecipeFromUrlFlow`): diálogo pede
a URL, busca, e ou abre o formulário preenchido ou mostra o erro via
`showAppSnackBar`.

---

## C8 — import por foto/OCR

Sem marcação nenhuma tipo o JSON-LD do C7 — é **heurística por
palavra-chave de seção** sobre as linhas que o reconhecedor de texto
devolveu, na ordem em que apareceram na foto.

### Serviço (`lib/data/services/recipe_ocr_service.dart`)

`RecipeOcrService.importFromPhoto(ImageSource)`:
1. `image_picker` tira/escolhe a foto (`imageQuality: 100`, sem compressão —
   o pré-processamento abaixo precisa do máximo de detalhe).
2. **Pré-processamento local** (`_preprocessForOcr`, roda em `compute()` —
   isolate separada, senão imagem grande de câmera travaria a UI e o loader
   pararia de animar): escala de cinza + `img.normalize` (estica o
   contraste pro range máximo). Ajuda foto desbotada/mal iluminada; **não
   resolve fonte cursiva** — isso é limite do reconhecedor
   (`google_mlkit_text_recognition`, script latino, feito pra texto
   impresso) em si, não da imagem de entrada. Se `decodeImage` falhar por
   qualquer motivo, cai pra foto original sem pré-processar — nunca quebra
   o import por causa disso.
3. `TextRecognizer.processImage` roda o OCR on-device na foto (processada
   ou original).
4. `parseOcrLinesMulti(recognized.text.split('\n'))` monta um ou mais
   `ImportedRecipe`.
5. **`finally`: apaga o arquivo original e o processado** — a foto só existe
   em disco durante o reconhecimento (RF-06.10: nunca fica salva). Apagar é
   best-effort (`try/catch` silencioso) — não falha o import se o SO não
   deixar apagar na hora.

### Parser (`lib/domain/engine/ocr_recipe_import.dart`)

`parseOcrLines(List<String>)` — pipeline:

1. **Limpeza por linha** (`_cleanLine`): tira marcador de lista no início
   (`_leadingBullet` — `•`,`-`,`*`... só ancorado em `^`, nunca toca a barra
   `/` de fração no meio da linha), legenda de foto colada no fim
   (`_photoCaptionSuffix`, `"— Foto: X"`), ícone solto no fim
   (`_trailingIconGlyph`).
2. **Filtro de ruído de interface** (`_isChromeNoise`) — descarta linha
   inteira antes de qualquer detecção de seção. Cobre bastante chão,
   acumulado testando prints reais: botão de rede social inteiro
   ("seguir"/"curtir"...), `@handle`/`#hashtag` sozinho, contador com
   palavra ("1,2 mil curtidas") ou só número ("859 mil"), relógio/bateria da
   barra de status, aba de site/busca grudada numa linha (`_looksLikeNavTabBar`)
   ou em linhas separadas (`_dropNavTabRuns`), nome de conta próprio
   ("Você"), tempo relativo ("há 3 d"), frase de curtida ("Curtido por X e
   outras N pessoas", pode vir em 2 linhas), placeholder de campo de
   resposta, nome de usuário sem `@` (token com `_`), glyph isolado, `•` no
   meio da linha (separador de UI tipo "Local • Categoria"), abas de busca
   do Google, selo "Visão geral criada por IA".
3. **Marcador de fim de lista** (`_sectionStopMarker`) — widget de
   sugestão/anúncio ("Faltou algo? Tenta essas", "Receitas relacionadas",
   "Globoplay"...) marca onde a lista de ingredientes para, mesmo sem achar
   um "Modo de preparo" real depois (comum em print cortado antes de
   chegar lá).
4. **Detecção de seção** via `_ingredientsHeading`/`_stepsHeading` (aceitam
   `:` opcional e texto colado depois, capturado no grupo nomeado `rest`).
   Sem heading nenhum, melhor esforço: 1ª linha = nome, resto avaliado
   linha a linha por `_looksLikePrepProse` (verbo de preparo no início,
   `_numberedStepPrefix`, ou frase longa terminando em ponto) pra achar onde
   a lista de ingrediente acaba e o preparo começa (`_ingredientRunEnd`) —
   cobre caderno/livro de receita sem rótulo nenhum.
5. **Passos numerados** (`_splitSteps`) — junta linha quebrada do mesmo
   passo quando acha numeração ("1.", "Passo 2:"); sem numeração, cada
   linha vira um passo.
6. `fixOcrDigitLetterConfusion` (do C1, ver
   [motor de ingredientes](06-motor-de-ingredientes.md#c1--parseingredientline-libdomainengineingredient_parserdart))
   roda em toda linha de ingrediente/passo antes de devolver.

### Várias receitas numa foto só (`parseOcrLinesMulti`)

Foto de página de livro/caderno numerado traz mais de uma receita.
`_multiRecipeMarker` (`^(?:\d+|[Il])\)\s+\S` — aceita "I)"/"l)" além de
"1)", porque o mesmo erro de OCR que troca "1" por "I" no marcador também
troca "1" por "I" na quantidade da linha de baixo) só conta como separador
de receita quando aparece **2+ vezes** na mesma foto (uma vez só é o número
da receita atual, não um separador). Com 2+, roda `parseOcrLines` em cada
trecho separado; sem isso, devolve a mesma receita única de sempre (lista
com 1 item, ou vazia se não achou texto nenhum).

### Ponto de entrada e revisão múltipla

`ExpandingCreateMenu` → "Importar de foto" → `recipe_ocr_flow.dart`
(`importRecipeFromPhotoFlow`): sheet "Tirar foto"/"Escolher da galeria" →
`_OcrLoadingDialog` (bloqueante, `barrierDismissible: false`, com
`BrandLoader` — pedido explícito do usuário: "pode gastar tempo lendo o
arquivo, desde que deixe um loader na tela") → roda o serviço.

Com 1 receita, pula direto pro formulário, igual ao C7. Com 2+, mostra
`_RecipeInclusionSheet` — uma folha com `CheckboxListTile` por receita
achada, todas marcadas por padrão — e abre o formulário **uma vez por
receita marcada**, em sequência (`_reviewRecipesOneByOne`, `context.push`
em loop) — cada uma passa pela revisão normal do formulário, uma de cada
vez, nunca em lote sem revisão.

---

**Limites conhecidos, sem solução por texto puro** (documentados no código
pra não serem re-investigados à toa):
- Fonte cursiva/manuscrita — outra API do ML Kit (Digital Ink Recognition,
  lê o traço sendo desenhado), não serve pra foto estática.
- Nome de site/marca sozinho numa linha antes do título de verdade pode
  vazar pro campo "nome" — não dá pra distinguir "isso é uma marca" de
  "isso é um nome de receita curto" só pelo texto, sem posição/tamanho de
  fonte (o OCR devolve bounding box, mas o parser hoje só usa o texto puro
  concatenado).

Voltar ao [índice](../arquitetura-e-fluxo.md).
