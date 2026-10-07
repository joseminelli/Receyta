# Guia: site do Receyta em Vue, no design do app

> Este guia é para uma IA (ou pessoa) que vai construir o site de divulgação do
> **Receyta** em **Vue 3**, herdando a linguagem visual do aplicativo. Leia tudo
> antes de escrever código. Onde este guia e as **imagens do app** divergirem,
> **as imagens vencem**: o app evoluiu depois do plano original.

## 0. Como trabalhar com este material

Você receberá no projeto Vue:

1. **Imagens do app** (telas reais e a marca). São a fonte da verdade visual.
2. **O plano de implementação do app** (`plano-app-receitas.md`). A seção
   "9. Design system" é a origem deste guia; os recursos estão nas seções de
   requisitos e blocos.
3. **Este guia**: traduz o design de Flutter para web.

Ordem sugerida:

1. Olhe todas as imagens. Anote o que se repete: cabeçalho escuro com textura,
   cartões arredondados, números enormes, botões em pílula.
2. Monte os **tokens** (seção 2) e a **tipografia** (seção 3) antes de qualquer
   página.
3. Faça o componente de **textura** (seção 5) e confira contra as imagens.
4. Só então monte as páginas (seção 8).

Regra de ouro: **o site deve parecer da mesma família do app**, não uma página
de modelo genérica com as cores trocadas. Se uma escolha sua não aparece em
nenhuma imagem do app, prefira a mais sóbria.

---

## 1. Princípios do design (a "personalidade")

Resumo da seção 9.1 do plano, ajustado ao que o app é hoje:

- **Maximalismo moderno com hierarquia.** Cor saturada, blocos grandes e tipo
  enorme. O excesso vem de **escala tipográfica e blocos de cor**, não de
  enfeite.
- **Superfícies chapadas.** Cartões sem borda grossa, sem gradiente, sem
  glassmorphism. A separação é feita por **bloco de cor e raio grande**.
  Sombra: quase nunca; quando existir, é curta e discreta (ex.: uma barra
  flutuante).
- **Números são ilustração.** Tempo, porções, contagem e passos aparecem em
  escala gigante, "sangrando" na borda do bloco. Use isso nos números do site
  (ex.: "30 min", "4 passos", "0 anúncios").
- **Salto de escala extremo.** Título de 48–120 px convivendo com rótulo de
  10 px em caixa alta. O contraste de tamanho carrega a personalidade.
- **Forma: ou pílula, ou raio grande.** Nada de cantos de 4–8 px.
- **Textura só onde substitui foto** (cabeçalhos, blocos de destaque, tiles),
  **nunca atrás de texto corrido**.
- **Ornamento cede à função.** Seções de leitura (FAQ, política de
  privacidade) são sóbrias: fundo chapado, texto à vontade.
- **Sem emojis na interface.** Ícones simples de traço (estilo Material
  "outlined"/"rounded").
- Texto em **português do Brasil**, direto e caloroso (seção 9).

---

## 2. Cores

### 2.1 Tokens (tema claro, o oficial)

Crie `src/styles/tokens.css`. **Nenhuma cor em hexadecimal fora deste
arquivo** (regra do app: toda cor vem de token).

```css
:root {
  /* Superfícies e texto */
  --ink: #16150f;          /* escuro principal; texto forte; barra de navegação */
  --ink-soft: #2b2a20;     /* chips/superfícies elevadas SOBRE ink */
  --paper: #f5f2ea;        /* fundo claro principal */
  --paper-soft: #e9e5d8;   /* cartão neutro, chip sobre paper */
  --text-body: #3d3b30;    /* corpo de texto sobre paper */
  --text-muted: #8a8674;   /* rótulos e metadados sobre paper */

  /* Acentos */
  --lime: #d6f45a;         /* AÇÃO e estado ativo — só sobre ink */
  --coral: #ff5a38;        /* seção Receitas */
  --coral-light: #ff7a5e;  /* números ilustrativos sobre coral */
  --violet: #7b6cf6;       /* seção Semana / calendário */
  --violet-deep: #6558e0;  /* superfícies sobre violet */
  --danger: #c0203f;       /* erro e ação destrutiva (frio, longe do coral) */
  --on-saturated: #ffffff; /* texto sobre coral/violet: sempre branco puro */
  --coral-muted: #ffb3a4;  /* rótulo secundário sobre coral */
  --violet-muted: #c2bcfa; /* rótulo secundário sobre violet */

  /* Tons da textura (variante do próprio matiz do bloco, contraste ~12%) */
  --coral-pattern: #ff7a5e;
  --violet-pattern: #9a8ef9;
  --ink-pattern: #2b2a20;
  --ink-pattern-alt: #37362a; /* 2º tom, só do módulo "diagonal" */
  --lime-pattern: #c2e33f;

  /* Raios e espaços */
  --radius-sm: 16px;
  --radius-md: 20px;
  --radius-lg: 26px;
  --radius-pill: 99px;
  --space-xs: 8px;
  --space-sm: 12px;
  --space-md: 16px;
  --space-lg: 24px;
  --space-xl: 32px;
  --space-xxl: 48px;
  --gutter: 18px; /* margem lateral padrão no celular */
}
```

### 2.2 Cores opcionais de azulejo (para variar blocos)

O app permite à pessoa escolher outras cores para receitas e pastas. No site,
use-as com parcimônia, para variar cartões de recursos:

| Nome | Fundo | Padrão (mais claro 16%, mostarda mais escuro 10%) | Texto sobre ele |
|---|---|---|---|
| mar | `#0f8b8d` | derivado | branco |
| framboesa | `#d92b63` | derivado | branco |
| mostarda | `#f2b134` | derivado | **ink** |
| cobalto | `#2f5bea` | derivado | branco |
| floresta | `#2e7d4f` | derivado | branco |
| terra | `#8a4b2e` | derivado | branco |

`lime` também leva texto **ink**. Todos os outros fundos saturados levam
branco.

### 2.3 Cor tem papel semântico

| Seção do app | Cor dominante | Uso no site |
|---|---|---|
| Receitas | `coral` | blocos sobre receitas, fotos, importação |
| Semana (calendário) | `violet` | planejamento, sugestões |
| Compras | `ink` (escura) | lista de compras, widgets, modo mercado |
| Ação / destaque | `lime` (sobre ink) | botão principal, estado ativo |

### 2.4 Regras de pareamento (obrigatórias)

1. **`lime` nunca sobre `paper`.** O contraste reprova. `lime` só aparece
   **sobre `ink`** (como texto, ícone ou fundo de botão com texto `ink`).
2. Texto sobre `coral`/`violet` é **branco puro**. Rótulo secundário usa a
   versão clara do próprio matiz (`--coral-muted`, `--violet-muted`), **nunca
   cinza**.
3. **No máximo duas cores saturadas por tela/seção**: uma dominante e uma de
   apoio.
4. **Container nunca é tingido com cor de acento.** Fundo de cartão, chip e
   pílula é `paper`, `paper-soft` ou `ink`. Acento aparece em **texto, ícone,
   borda fina ou como bloco de seção inteiro**, não como "fundo claro tingido".
5. Contraste mínimo AA (4,5:1) em todo par texto/fundo. Confira com uma
   ferramenta antes de entregar.

### 2.5 Tema escuro (opcional)

O app tem um tema escuro: `paper` vira `#1e1d16`, `paper-soft` `#2b2a20`, `ink`
vira `#f5f2ea`, `lime` `#c2e33f`, `coral` `#e64820`, `violet` `#6957d8`,
`text-body` `#b8b5a8`, `text-muted` `#776b5f`. Se o site oferecer tema escuro,
use `prefers-color-scheme` e redefina os tokens (não inverta com filtro). Se
não, **não implemente**: o tema claro é o oficial.

---

## 3. Tipografia

Duas famílias, papéis rígidos.

### 3.1 Display: Bricolage Grotesque, peso 800

Usada em títulos, nomes, números ilustrativos e quantidades.

- Fonte **variável**. Instale `@fontsource-variable/bricolage-grotesque` (ou
  baixe o `.woff2` e hospede você mesmo; **nada de CDN em runtime**). Licença
  SIL OFL (livre para uso comercial; mantenha o arquivo de licença no projeto).
- O app usa o eixo `wght`: aplique **`font-variation-settings: "wght" 800`**
  além de `font-weight: 800`.
- **Assinatura do estilo:** `letter-spacing: -0.045em` e `line-height: 0.92`.
  Sem isso o layout perde a personalidade. Não relaxe esses valores.

```css
.display {
  font-family: "Bricolage Grotesque Variable", "Bricolage Grotesque", system-ui, sans-serif;
  font-weight: 800;
  font-variation-settings: "wght" 800;
  letter-spacing: -0.045em;
  line-height: 0.92;
}
```

### 3.2 Interface: fonte do sistema, 400/500

Corpo, rótulos, metadados e botões. **Nunca acima de 500.**

```css
body {
  font-family: system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", sans-serif;
  font-weight: 400;
  color: var(--text-body);
  background: var(--paper);
}
```

### 3.3 Escala (web)

Use `clamp()` para a escala crescer do celular ao desktop. Os valores
"app" são os do Flutter; o site pode ir além nos títulos de herói.

| Papel | App (px) | Web sugerida | Família |
|---|---|---|---|
| Display XL, número ilustrativo | 86–130 | `clamp(88px, 14vw, 180px)` | Bricolage 800 |
| Display L, título de página/herói | 44–52 | `clamp(44px, 7vw, 96px)` | Bricolage 800 |
| Display M, título de cartão | 25 | `clamp(24px, 2.4vw, 32px)` | Bricolage 800 |
| Display S, título de seção | 22–24 | `clamp(22px, 2.2vw, 28px)` | Bricolage 800 |
| Quantidade / métrica | 17–28 | 20–32 | Bricolage 800 |
| Corpo | 14 | 16–18 (leitura confortável) | Sistema 400 |
| Rótulo | 11–12 | 12–13 | Sistema 500 |
| **Rótulo em caixa alta** | 10 | 10–11, `letter-spacing: .16em`, `text-transform: uppercase` | Sistema 500 |

O rótulo em caixa alta é muito usado como "sobretítulo" acima de um display
grande (ex.: `MODO COZINHA` em lima sobre ink, e abaixo o título grande).

---

## 4. Forma e espaço

- **Raios:** cartão grande 20 · cartão pequeno 16 · folha/painel/herói 26 ·
  chip, botão, barra de navegação e campo **99 (pílula)**.
- **Sem meio-termo.** Ou é pílula, ou é raio grande.
- **Margem lateral:** 18 px no celular. No desktop use um contêiner centrado
  (sugestão: `max-width: 1120px`, com `padding-inline: var(--gutter)` no
  celular e mais folga em telas largas).
- **Área mínima de toque:** 48 px de altura em botões e links de ação.
- **Cabeçalho de página:** bloco escuro (`ink`) com os **cantos de baixo
  arredondados em 26 px** e uma textura no canto superior direito (seção 5).
- **Sangramento:** números gigantes podem ultrapassar a borda do bloco
  (`overflow: hidden` no pai). É intencional e recorrente.

---

## 5. Textura: o "azulejo modernista"

Referência: Athos Bulcão, **não** azulejo colonial. É geometria pura em **tom
sobre tom**.

### 5.1 Regras

- **Escala grande:** tile de **40 px**, nunca abaixo de 32 px. Padrão miúdo
  volta a parecer artesanal.
- **Tom sobre tom, contraste ~12%:** a cor do padrão é uma variante clara do
  próprio matiz do bloco (tokens `*-pattern`). É a camada mais fraca da
  hierarquia.
- **No máximo dois módulos por tela/seção**, sempre com um bloco chapado ao
  lado para respiro.
- **Onde entra:** cabeçalhos, blocos de destaque, cartões de recurso, cantos de
  seção, "tiles" que substituem foto.
- **Onde nunca entra:** atrás de texto corrido, listas, FAQ, política de
  privacidade, rodapé, menu, formulários. Se a pessoa lê linha a linha, o
  fundo é **chapado**.
- Com textura no bloco, números ilustrativos viram **branco sólido** (senão
  somem no padrão).

### 5.2 Os módulos (SVG, viewBox 40×40)

Os nove módulos do app. Os quatro primeiros são os originais; os cinco últimos
são opcionais. Cada trecho abaixo é o conteúdo de um `<pattern>` de 40×40;
`C` = cor do padrão, `C2` = segundo tom (só o `diagonal`).

```html
<!-- arco: quarto de círculo ancorado no canto superior esquerdo -->
<path d="M0 0H40A40 40 0 0 1 0 40Z" fill="C"/>

<!-- meiaLua: meios-discos alternados (esquerda e direita) -->
<path d="M0 0A20 20 0 0 1 0 40Z" fill="C"/>
<path d="M40 40A20 20 0 0 1 40 0Z" fill="C"/>

<!-- diagonal: dois triângulos, dois tons -->
<path d="M0 0H40L0 40Z" fill="C"/>
<path d="M40 0V40H0Z" fill="C2"/>

<!-- ponto: círculos em grade deslocada -->
<circle cx="10" cy="10" r="6.4" fill="C"/>
<circle cx="30" cy="30" r="6.4" fill="C"/>

<!-- losango -->
<path d="M20 0L40 20L20 40L0 20Z" fill="C"/>

<!-- onda: uma senoide por tile, emenda nos dois lados -->
<path d="M-4 20Q5 4.8 20 20T44 20" fill="none" stroke="C"
      stroke-width="5.6" stroke-linecap="round"/>

<!-- xadrez -->
<rect x="0" y="0" width="20" height="20" fill="C"/>
<rect x="20" y="20" width="20" height="20" fill="C"/>

<!-- faixa: listras a 45° que se emendam entre tiles -->
<g stroke="C" stroke-width="7.9">
  <line x1="-2" y1="42" x2="42" y2="-2"/>
  <line x1="-22" y1="22" x2="22" y2="-22"/>
  <line x1="18" y1="62" x2="62" y2="18"/>
</g>

<!-- circulo: quarto de disco em cada canto (vizinhos completam círculos) -->
<circle cx="0" cy="0" r="20" fill="C"/>
<circle cx="40" cy="0" r="20" fill="C"/>
<circle cx="0" cy="40" r="20" fill="C"/>
<circle cx="40" cy="40" r="20" fill="C"/>
```

A `onda` e a `faixa` são aproximações em SVG: compare com as imagens do app e
ajuste a curva e a espessura até ficar igual.

### 5.3 Pareamento padrão (cor ↔ módulo)

| Módulo | Fundo | Cor do padrão |
|---|---|---|
| arco | `--coral` | `--coral-pattern` |
| meiaLua | `--violet` | `--violet-pattern` |
| diagonal | `--ink` | `--ink-pattern` e `--ink-pattern-alt` |
| ponto | `--lime` | `--lime-pattern` |
| losango | `--ink` | `--ink-pattern` |
| onda | `--violet` | `--violet-pattern` |
| xadrez | `--coral` | `--coral-pattern` |
| faixa | `--lime` | `--lime-pattern` |
| circulo | `--coral` | `--coral-pattern` |

Para cores opcionais sem token de padrão, derive: misture o fundo com branco
em ~16% (mostarda: com preto em ~10%). O segundo tom do `diagonal` (fora do
`ink`) é o padrão escurecido em 12%.

### 5.4 Componente `TilePattern.vue`

Gere o fundo como **SVG inline** (um `<svg>` com `<pattern>`), sem imagem
externa, para repetir sem emenda e escalar nítido. Esqueleto:

```vue
<script setup lang="ts">
import { computed } from "vue";

type Motif =
  | "arco" | "meiaLua" | "diagonal" | "ponto" | "losango"
  | "onda" | "xadrez" | "faixa" | "circulo";

const props = withDefaults(
  defineProps<{
    motif: Motif;
    background: string;      // ex.: "var(--coral)"
    patternColor: string;    // ex.: "var(--coral-pattern)"
    patternColorAlt?: string;
    tile?: number;           // px; padrão 40, mínimo 32
  }>(),
  { tile: 40 },
);

const size = computed(() => Math.max(32, props.tile));
const id = `tp-${Math.random().toString(36).slice(2, 8)}`;
// shapes[props.motif] devolve o miolo SVG da seção 5.2 (viewBox 40x40)
</script>

<template>
  <svg class="tile-pattern" aria-hidden="true" focusable="false"
       width="100%" height="100%" preserveAspectRatio="none">
    <defs>
      <pattern :id="id" :width="size" :height="size"
               patternUnits="userSpaceOnUse"
               :patternTransform="`scale(${size / 40})`">
        <!-- o miolo do módulo, com fill/stroke = patternColor -->
      </pattern>
    </defs>
    <rect width="100%" height="100%" :fill="background" />
    <rect width="100%" height="100%" :fill="`url(#${id})`" />
  </svg>
</template>
```

Use sempre posicionado **atrás** do conteúdo (`position:absolute; inset:0;
z-index:0`) com `aria-hidden="true"`. Um uso típico é um canto: um `<div>` de
~240×240 px, `top:-40px; right:-30px`, dentro de um cabeçalho com
`overflow:hidden`.

---

## 6. Componentes

Crie estes componentes pequenos e reutilize-os em todas as páginas.

### 6.1 `PillButton`

Botão em pílula (`border-radius: 99px`), altura mínima 48 px, padding
horizontal 24 px (16 px na versão compacta), rótulo em 14 px/500. Sem borda,
sem sombra, sem gradiente.

| Variante | Fundo | Texto | Quando |
|---|---|---|---|
| `primary` | `--ink` | `--lime` | Ação principal sobre fundo claro |
| `accent` | `--lime` | `--ink` | Ação principal sobre fundo escuro/saturado |
| `secondary` | `--paper-soft` | `--ink` | Ação secundária sobre `paper` |
| `ghost` | transparente | `--ink` | Ação terciária |
| `danger` | `--danger` | `#fff` | Ação destrutiva |

Desabilitado: mistura o fundo a 35% sobre `paper` (não vira cinza). Foco:
anel visível (2 px, `--ink` ou `--lime` sobre escuro).

### 6.2 Cartão

`background: var(--paper-soft)`, `border-radius: var(--radius-md)`, sem borda e
sem sombra. Em seção escura, cartão é `--ink-soft`.

### 6.3 Medalhão de ícone

Círculo de 44–48 px, fundo `--ink`, ícone **lima** de 22 px. É o "marcador" de
cada linha de recurso. Em linhas de cabeçalho de painel, o ícone fica num
**quadrado arredondado** (16 px) só com borda de 2 px (`--ink`) e fundo
`--paper`, para diferenciar de itens de ação.

### 6.4 Chip / pílula de rótulo

Pílula `--paper-soft` com texto `--ink`, ou **apenas borda** fina de 1,5 px na
cor do acento com fundo `--paper` (acento em borda/texto, nunca em fundo).

### 6.5 Número ilustrativo (`HeroNumber`)

Display XL em branco sólido (sobre bloco saturado) ou `--ink` (sobre `paper`),
que pode **sangrar** pela borda do bloco. Exemplo de uso: `30` + rótulo `MIN`,
`0` + `ANÚNCIOS`, `6` + `PESSOAS NA CASA`.

### 6.6 Barra de navegação do site

**Pílula flutuante `--ink`**, item ativo em **`--lime`** (texto `--ink`),
inativos só texto claro. No celular, vira um botão de menu que abre uma folha
(`--paper`, raio superior 26 px) com os links em Display S.

### 6.7 Cabeçalho escuro de seção

Bloco `--ink`, cantos inferiores 26 px, rótulo em caixa alta lima, título
Display L em branco, e textura (`diagonal` ou `ponto`) no canto superior
direito, tom sobre tom.

### 6.8 Painéis recolhíveis (FAQ)

Cartão `--paper-soft`, título em Display S, resumo de uma linha em
`--text-muted`, chevron que gira 180° ao abrir (220 ms). Um painel aberto por
vez. O conteúdo da resposta aparece sobre fundo chapado (sem textura).

### 6.9 Moldura de celular (para as capturas)

Use as imagens de `assets/app/*.jpg` dentro de uma moldura simples: retângulo
com raio ~36 px, borda `--ink` de 6–8 px, **sem** sombra pesada, imagem com
`object-fit: cover`. Pode inclinar 2–4° ou escalonar duas capturas lado a
lado em cima de um bloco colorido (coral para Receitas, violet para Semana,
ink para Compras).

---

## 7. Movimento e interação

- **Sutil e rápido:** transições de 180–260 ms, `ease-out`.
- **Um momento "elástico" por seção**, no máximo (como o "bounce" do app ao
  entrar): entrada do título ou do botão principal com leve *overshoot*.
- Hover em botões: escurecer/clarear o fundo ~6%; nunca sombra.
- Respeite **`prefers-reduced-motion: reduce`**: desligue o overshoot e as
  entradas animadas.
- Rolagem: entradas por *fade + translateY(12px)* ao entrar na tela, uma vez.
- Nada que pisque, nada de parallax pesado.

---

## 8. Estrutura do site

### 8.1 Páginas

| Rota | Conteúdo |
|---|---|
| `/` | Página principal (seção 8.2) |
| `/privacidade` | Política de privacidade (obrigatória para a Play) |
| `/excluir-conta` | Como excluir a conta e os dados (a Play exige uma **URL pública** para isso) |
| `/termos` | Termos de uso (simples) |
| `/suporte` | Contato / perguntas frequentes |

As páginas de política e exclusão são **sóbrias**: fundo `--paper`, texto em
coluna de ~680 px, títulos Display S, **sem textura atrás do texto**.

### 8.2 Página principal: seções sugeridas

1. **Herói** (bloco `--ink` com textura no canto): rótulo `RECEYTA`, título
   Display XL: *"O lugar onde suas receitas moram."*; subtítulo curto; botão
   `accent` "Baixar na Google Play" (selo oficial da Play) e link secundário
   "Ver como funciona". À direita, 2 capturas em moldura de celular.
2. **Para quem é** (`--paper`): o parágrafo do "receita em cinco lugares
   diferentes": print, caderno da avó, favorito do Instagram, papel na
   gaveta.
3. **Receitas** (bloco `--coral`, módulo `arco`): receitas do seu jeito,
   pastas, fotos, busca, importar por link ou foto. Captura da tela de
   receitas.
4. **A semana** (bloco `--violet`, módulo `meiaLua`): calendário por refeição,
   semana inteira, sugestões. Captura do calendário.
5. **A lista se faz sozinha** (bloco `--ink`, **sem** textura atrás de texto):
   soma de quantidades ("500 g + 800 g = 1,3 kg"), corredores, de qual receita
   veio, tela escura para o mercado. Captura da lista.
6. **Modo cozinha**: tela sempre ligada, passos grandes, timers no passo.
   Número ilustrativo gigante (ex.: `01`).
7. **Casa**: dividir lista, calendário e despensa com quem mora com você, por
   código, link ou QR; você escolhe o que compartilha.
8. **Widgets**: "Hoje" e "Compras" na tela inicial.
9. **Seus dados são seus**: funciona offline; conta opcional; backup;
   exportar tudo/uma receita/PDF; enviar por WhatsApp; **sem anúncios**.
10. **Perguntas frequentes**: painéis recolhíveis (seção 6.8).
11. **Chamada final** (bloco `--lime`? **cuidado:** lima como bloco de seção
    inteira é permitido, com texto `--ink`; mas **nunca** lima como texto
    sobre `paper`) com o botão de download.
12. **Rodapé** `--ink`: logo, links (privacidade, exclusão de conta, termos,
    suporte), "Feito com carinho para quem ama cozinhar".

Cada seção usa **uma cor dominante** (coral, violet ou ink) e no máximo uma de
apoio. Alterne claro/escuro para criar ritmo: `ink` → `paper` → `coral` →
`paper` → `violet` → `ink` …

### 8.3 Responsivo

- **Mobile first.** O app é de celular; a maior parte dos visitantes virá de
  link de celular.
- Grade: 1 coluna no celular, 2 colunas (texto + captura) a partir de ~860 px.
- Capturas empilham abaixo do texto no celular, nunca cortadas.
- Botões de largura total no celular.
- Sem rolagem horizontal. Teste em 360, 390, 768, 1024 e 1440 px.

---

## 9. Voz e texto

- **Português do Brasil**, tom direto, caloroso, sem jargão e sem exagero de
  marketing.
- Frases curtas. Verbos de ação ("Guarde", "Planeje", "Cozinhe").
- Use a descrição do app como base de copy (a da Play). Mensagens-chave:
  - "Suas receitas, do seu jeito."
  - "A lista de compras se monta sozinha."
  - "Funciona offline. Conta é opcional. Sem anúncios."
  - "Divida a cozinha com quem mora com você."
- Evite prometer o que o app não faz. **Não afirme** recursos que não
  aparecem no plano ou nas imagens.
- Sem emojis. Números e símbolos em tipo grande já fazem o papel visual.

---

## 10. Acessibilidade e desempenho

- Contraste AA em tudo (seção 2.4). Texto sobre textura só em blocos
  saturados grandes e em branco sólido.
- Alvos de toque ≥ 48 px. Foco sempre visível. Ordem de tabulação lógica.
- `alt` descritivo nas capturas; texturas com `aria-hidden="true"`.
- Hierarquia de títulos correta (`h1` único por página).
- Imagens em **WebP/AVIF** com `width`/`height` definidos e `loading="lazy"`
  (exceto o herói). Capturas do app: comprima (≤ 150 KB cada).
- Fonte: carregar só os pesos usados, `font-display: swap`, pré-carregar o
  arquivo do display.
- Metas: LCP < 2,5 s no celular, sem *layout shift*.
- SEO: `title`, `description`, `lang="pt-BR"`, Open Graph com imagem do herói,
  `robots`, `sitemap.xml`. Considere pré-renderização estática (SSG).

---

## 11. Estrutura sugerida do projeto (Vue 3 + Vite)

```
src/
  styles/
    tokens.css          cores, raios, espaços (única fonte de hex)
    base.css            reset, tipografia, foco, prefers-reduced-motion
  components/
    TilePattern.vue     textura SVG (seção 5)
    PillButton.vue
    SectionHeader.vue   rótulo caps + título display
    HeroNumber.vue
    PhoneFrame.vue      moldura das capturas
    FeatureRow.vue      medalhão + título + texto
    FaqPanel.vue
    SiteNav.vue         pílula ink
    SiteFooter.vue
  sections/             uma por seção da home (HeroSection.vue, ...)
  pages/                HomePage.vue, PrivacyPage.vue, DeleteAccountPage.vue, ...
  assets/
    brand/              logos
    app/                capturas do app
    fonts/              Bricolage (ou via @fontsource)
  router.ts
  main.ts
```

Diretrizes:

- **Vue 3 + `<script setup>` + TypeScript.** `vue-router` para as rotas. Sem
  biblioteca de UI pronta (Vuetify, Element etc.): ela traria o visual errado.
  CSS puro com variáveis (ou Tailwind **configurado com os tokens acima**, se
  preferir; nesse caso, **desative** as cores/raios padrão para não vazarem).
- Nunca escreva hexadecimal nem `px` solto de raio/espaço fora dos tokens.
- Componentes pequenos e sem lógica de negócio. O site é estático.
- Pré-renderização (por exemplo `vite-ssg`) para SEO e velocidade.

---

## 12. Marca e imagens

No repositório do app (copie o que precisar para o projeto do site):

- `assets/brand/` — `logo.png`, `logoFundoPreto.png` (para fundos escuros),
  `LogoFundoBranco.png`, `logoIcon.png`, `logoInverted.png`,
  `bannerFundoBranco.png`, `Appicon.png` (ícone do app), `typography.png`.
- `assets/app/` — capturas: `HomePage`, `RecipePage`, `CalendarPage`,
  `ListPage`, `ShopListsPage`, `PrepareMode`, `IngredientsPage`, `profilePage`.
- Marca: **wordmark em Bricolage Grotesque 800**, tracking −0,045em, com o
  **`y` em coral**. Nunca reescrever o `y` em outro peso ou fonte. Prefira
  **SVG** (peça os SVGs ao dono do projeto; o logotipo tem o `y` em curvas) a
  PNG. O símbolo é uma bandeja de garçom reduzida a três formas (pegador,
  cúpula, barra).
- Ícone do app: um quarto de círculo (módulo `arco`) em coral sobre `paper`.
  Use-o como favicon e *touch icon*.
- Respeite o espaço livre ao redor do logo (≥ metade da altura do símbolo).

---

## 13. O que NÃO fazer

- Gradientes, *glassmorphism*, neon, sombras pesadas, bordas grossas.
- `lime` como texto ou ícone sobre `paper`.
- Bloco tingido de acento como "fundo claro" de cartão (acento é para texto,
  ícone, borda fina ou seção inteira).
- Textura atrás de texto corrido, FAQ, política ou formulário.
- Mais de dois módulos de textura na mesma seção.
- Cantos de 4–8 px. Tudo é 16, 20, 26 ou pílula.
- Texto de interface acima do peso 500.
- Display sem o `letter-spacing` negativo e o `line-height` baixo.
- Bibliotecas de UI genéricas, ilustrações vetoriais "de banco de imagens",
  emojis, ícones coloridos.
- Prometer funcionalidades que o app não tem.

---

## 14. Checklist de entrega

- [ ] Tokens em `tokens.css`; nenhum hexadecimal fora dele.
- [ ] Bricolage 800 com `letter-spacing -0.045em` e `line-height 0.92` nos
      títulos; corpo em fonte do sistema 400/500.
- [ ] Botões, chips, campos e navegação em pílula; cartões 16/20/26.
- [ ] Texturas só em blocos (nunca sob texto corrido), tom sobre tom.
- [ ] No máximo duas cores saturadas por seção; `lime` só sobre `ink`.
- [ ] Capturas do app em molduras; comparar lado a lado com as imagens do app.
- [ ] Contraste AA conferido; alvos ≥ 48 px; foco visível; `prefers-reduced-motion`.
- [ ] Páginas `/privacidade` e `/excluir-conta` publicadas (URLs para a Play).
- [ ] Mobile first testado em 360/390/768/1024/1440 px.
- [ ] Lighthouse: desempenho, acessibilidade e SEO ≥ 90.
- [ ] Revisão final: o site parece **da mesma família** do app?
