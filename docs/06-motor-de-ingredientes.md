# O motor de ingredientes

> Parte 6 de 7 do guia técnico. [Índice](../arquitetura-e-fluxo.md) ·
> anterior: [Vocabulário rápido](05-vocabulario.md). Cobre o bloco C
> (C1–C6): parser, normalizador, catálogo e fuzzy match.

Até o bloco B, uma linha de ingrediente era só texto livre (`raw_text`) —
"2 xícaras de farinha de trigo, peneirada" ficava exatamente assim no banco,
sem quantidade, unidade ou ingrediente estruturados. O bloco C constrói, em
cima disso, um motor que **entende** essa linha sem nunca obrigar o usuário a
preencher formulário estruturado: ele digita como sempre digitou, e o motor
extrai o resto.

Tudo aqui é **Dart puro** — `lib/domain/engine/` não importa Flutter nem
Drift. É a peça que `RNF-06` (100% de cobertura) mais visa: sem depender de
widget ou banco de verdade, cada função testa em milissegundos com casos de
texto puro.

```
"2 xícaras de farinha de trigo, peneirada"
        │  parseIngredientLine (C1)
        ▼
quantity=2, unitCode='xicara', qualifier='peneirada', name='farinha de trigo'
        │  IngredientDao.getOrCreate (C2, usa normalize())
        ▼
normalizedKey='farinha trigo' → acha ou cria um IngredientRow
        │
        ▼
RecipeIngredientRow completo: rawText + quantity + unitId + ingredientId + qualifier
```

---

## C1 — `parseIngredientLine` (`lib/domain/engine/ingredient_parser.dart`)

Pega uma linha crua e devolve um `ParsedIngredientLine` (`rawText`,
`quantity`, `unitCode`, `qualifier`, `name`) — **nunca lança exceção**: linha
que não bate com nada vira `name = rawText`, o resto nulo. Essa garantia é o
motivo de ele poder rodar sem confirmação em cada linha digitada, inclusive
em rascunho de import (C7/C8) antes de qualquer revisão humana.

Ordem de extração, sempre da esquerda pra direita:

1. **Quantidade** — tenta bater um dos formatos, do mais específico pro
   genérico: intervalo (`"2 a 3"`, fica com o mínimo), fração mista com "e"
   ASCII/Unicode (`"1 e 1/2"`, `"1 e ½"`), fração mista sem "e" (`"1 1/2"`),
   fração ASCII (`"1/2"`), fração Unicode (`"½"`...`"⅞"`, tabela
   `_fractionChars`), decimal com vírgula (`"1,5"`), inteiro (`"2"`). Se nada
   bate no **início** da linha, varre palavra por palavra (`_extractQuantityAnywhere`)
   — cobre o caso de OCR "Farinha de trigo 1/4 xícara", quantidade no fim.
2. **Unidade** — casa contra `kSeedUnits` (`displayName`/`plural`, sem
   acento via `stripAccents` de `text_normalize.dart`), candidatos ordenados
   por tamanho decrescente pra "colher de sopa" vencer de "colher" sozinho.
   `_unitSynonyms` mapeia "colher"/"colheres" genérico pra `colher_sopa`
   quando não tem a forma completa.
3. **Conectivo** (`de`/`da`/`do`) — removido entre unidade e nome
   (`"xícara DE farinha"`). Também tratado entre fração e unidade
   (`"1/4 DE xícara"`), caso a 1ª tentativa de casar unidade falhe.
4. **Qualificador** — por vírgula (`"farinha, peneirada"` → nome="farinha",
   qualifier="peneirada") ou, sem vírgula, por termo final de
   `kSeedNormalizerTerms` (`kind == 'qualifier'`, ex. "a gosto", "em cubos").
5. **Nome** — o que sobra.

### OCR digit/letter confusion (`fixOcrDigitLetterConfusion`)

Fonte sem serifa faz o OCR (C8) ler "1" como "I"/"l"/"T" — "I dente de alho"
vira, depois da correção, "1 dente de alho". Só troca de volta quando o
resto da palavra ainda parece continuação de quantidade (fração logo depois,
ou unidade reconhecida) — assim "Iogurte"/"leite" não viram "1ogurte"/"1eite"
à toa. Usada tanto por `parseIngredientLine` quanto, direto, pelo import de
foto (C8) pra limpar o `rawText` que aparece na tela de revisão, não só a
quantidade extraída por baixo dos panos.

## C2 — `normalize` + `getOrCreate` (identidade do ingrediente)

`lib/domain/engine/ingredient_normalizer.dart`: `normalize(String)` produz a
`normalizedKey` — a chave de identidade do catálogo. Pipeline:
minúsculas → `stripAccents` → tira pontuação (regex `[^a-z0-9\s]`) → tira
stopword/qualificador de `kSeedNormalizerTerms` (unigrama e bigrama, ex.
"a gosto"/"em cubos" somem inteiros) → singulariza (`_singularize`,
heurística pt-BR: -ões/-ães/-ais/-eis/-ois→-al, -ns→-m, -res/-ses/-zes tira
"es", -s genérico tira "s"; best-effort, não é linguisticamente perfeito) →
junta com espaço.

`lib/data/database/daos/ingredient_dao.dart`: `IngredientDao.getOrCreate(displayName)`
roda numa `transaction()`: `SELECT` por `normalizedKey` exato → se não achar,
`SELECT` em `IngredientAliases` (nome que já foi confirmado como sinônimo,
ver C4) → se ainda não achar, cria um `IngredientRow` novo (`Uuid().v4()`).
`IngredientRepository.getOrCreate` (`lib/data/repositories/ingredient_repository.dart`)
é a casca `Result`-wrapped que a UI/Repository de receita usa.

## C3 — onde o parser entra no fluxo de salvar

O parser e o `getOrCreate` **não rodam sozinhos** — alguém precisa chamá-los.
Isso acontece em dois lugares:

**Salvar receita** (`RecipeRepository.saveDetail`,
[`data/repositories/recipe_repository.dart:155`](../lib/data/repositories/recipe_repository.dart)):
para cada linha de ingrediente digitada, roda `parseIngredientLine`; se o
formulário não trouxe um `ingredientId` já escolhido no autocomplete
(parâmetro paralelo `ingredientIds`), chama `_ingredientDao.getOrCreate`. Ou
seja: **toda receita salva resolve `quantity`/`unitId`/`ingredientId` de
verdade**, não só quando o usuário clica numa sugestão.

**Autocomplete no formulário** (`_IngredientAutocompleteField` em
[`features/recipes/recipe_form_page.dart:1020`](../lib/features/recipes/recipe_form_page.dart)) —
um `RawAutocomplete<Ingredient>` (molde do `_TagsField` que já existia pras
tags) que filtra `allIngredientsProvider` pelo **nome já extraído pelo
parser** (`parseIngredientLine(value.text).name`), não pela linha inteira —
assim digitar "2 xícaras de fari" já sugere "Farinha de trigo" mesmo com a
quantidade no meio do campo. Ao escolher, troca só o pedaço do nome,
preservando quantidade/unidade/qualificador já digitados
(`applyIngredientSuggestion`); `hasValidIngredientId` invalida o id
sozinho se o texto da linha mudar depois da escolha.

Achado documentado no código: `RawAutocomplete._select` (Flutter SDK)
sobrescreve o texto do campo pro nome escolhido **antes** de chamar
`onSelected` — por isso o texto original é capturado no `onTap` da sugestão
(`pendingPickText`), não dentro do `onSelected` (ali já viria sempre o texto
pós-clobber).

**Migração de dado antigo (C5)** — receitas salvas no bloco B (antes do C1
existir) só têm `raw_text`, sem `ingredientId`. `RecipeDao.findUnresolvedIngredients()`
(`WHERE ingredient_id IS NULL`) + `RecipeRepository.reprocessLegacyIngredients()`
rodam o mesmo parser+`getOrCreate` nelas — idempotente pelo próprio `WHERE`
(chamar de novo não acha nada pra reprocessar). Disparado uma vez no boot,
em `bootstrap.dart`, logo depois de `purgeExpired()`, silencioso, sem UI.

## C4 — fuzzy match (`lib/domain/engine/fuzzy_match.dart`)

Quando o match exato por substring do autocomplete não acha nada, entra
**a mesma lista de sugestão** (não é diálogo separado) com fallback fuzzy:

- `levenshteinDistance(a, b)` — distância de edição clássica (DP two-row).
- `normalizedSimilarity(a, b)` — `1 - distância / maior comprimento`.
- `isCloseMatch(a, b, {threshold = 0.85})` — aceita se `normalizedSimilarity`
  bate o limiar **ou** se é só 1 edição Levenshtein de distância numa
  palavra com 4+ letras (guarda contra falso positivo tipo "sal"/"sol"). A
  segunda via existe porque o limiar sozinho penaliza demais 1 letra trocada
  em palavra curta: "tomate"→"tomatr" dá 0.83 (abaixo do corte), enquanto
  "tomate"→"tomatee" (uma letra a mais) dá 0.857 e passava — inconsistente
  pro mesmo tipo de erro de digitação.

No autocomplete do formulário, o candidato fuzzy aparece rotulado "Você quis
dizer:" (`isFuzzy`/`pendingWasFuzzy`, mesmo truque do `pendingPickText`
acima — capturado no `onTap`, não no `onSelected`). Ao escolher, grava um
**alias** (`IngredientDao.addAlias` + `IngredientRepository.confirmAlias`)
com a chave normalizada do texto digitado — da próxima vez o match é exato
via `IngredientAliases`, sem passar por fuzzy de novo.

Na tela de gerenciar (C6), o mesmo `isCloseMatch` roda O(n²) sobre o
catálogo inteiro (pessoal, pequeno, sem custo real) pra sinalizar pares
prováveis de duplicata.

## C6 — gerenciar/mesclar (`lib/features/recipes/ingredients_page.dart`, rota `/ingredients`)

`IngredientDao.watchAllWithCounts()` — catálogo com contagem de uso (join
`LEFT OUTER` com `RecipeIngredients`, `GROUP BY`; a coluna `usage_count` da
própria tabela `Ingredients` nunca é incrementada em lugar nenhum — a
contagem é sempre ao vivo via join, não via coluna persistida).

`IngredientDao.merge(sourceId, targetId)`, transação:
1. reaponta `RecipeIngredients`/`ShoppingListItems` pro destino — **antes**
   de apagar a origem, porque `RecipeIngredients.ingredientId` é
   `onDelete: restrict` (apagaria e o banco recusaria a operação se a ordem
   fosse invertida);
2. preserva o nome e os aliases da origem como aliases do destino (digitar
   o nome antigo depois da fusão continua achando o ingrediente certo);
3. apaga a linha de origem.

`deleteIngredient(id)` só funciona sem uso — o `onDelete: restrict` faz o
banco recusar sozinho; a UI só mostra o botão quando `count == 0`, não
tenta e trata erro.

A tela (mesmo molde visual de `tags_page.dart`) lista cada ingrediente com
pílula de contagem, pílula extra coral "Parece com 'X' · mesclar" quando o
C4 acha um par parecido (2 toques até confirmar), botão de mesclar manual
(`ingredient_picker.dart`, bottom sheet igual ao `folder_picker.dart`), botão
de apagar quando `count == 0`, e busca client-side por nome.

## Onde isso aparece fora do formulário

`recipe_detail_page.dart` (`_IngredientRow`) reaproveita `parseIngredientLine`
**só pra exibição** (não mexe no dado salvo) pra montar um `RichText` com
quantidade em destaque + unidade por extenso numa coluna fixa — linha sem
quantidade reconhecida cai pro `rawText` cru, nada é escondido.

---

**Próximo:** [Importação de receitas](07-importacao-de-receitas.md) — de
link (C7) e de foto/OCR (C8), os dois alimentando este mesmo motor.
