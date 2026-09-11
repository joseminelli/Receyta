# Receyta — Como o projeto funciona

> Guia técnico de orientação. Escrito para quem já mexeu com Flutter + MVVM mas
> está enferrujado. Explica o *porquê* de cada peça, não só o *onde*. Baseado no
> código real ao fim do bloco B — não no plano, embora os dois combinem.
> Referências de arquivo usam caminho relativo a partir da raiz do repositório.

Dividido em 5 partes curtas, pensadas pra ler em sequência na primeira vez e
depois usar como referência avulsa:

1. **[Visão geral e MVVM](docs/01-visao-geral-e-mvvm.md)** — a stack em uma
   frase cada, o que View/ViewModel/Repository/DAO podem e não podem fazer,
   `freezed`, a estrutura de pastas real e um guia de "onde mexer".
2. **[O banco local](docs/02-banco-local.md)** — o que é SQLite na prática,
   por que Drift, as tabelas existentes, migrações versionadas, busca por
   texto (FTS5), soft delete/lixeira, seed, e o padrão `Result`/`Failure`.
3. **[Riverpod e o fluxo](docs/03-riverpod-e-fluxo.md)** — os quatro tipos de
   `Provider` usados no código, navegação com `go_router`, e um fluxo
   completo trilhado (salvar uma receita, do toque no botão até a lista
   atualizar sozinha).
4. **[Exemplos reais na View](docs/04-exemplos-na-view.md)** — cinco fluxos
   de código reais tirados de telas existentes (filtro de tag, busca com
   debounce, lixeira, arrastar receita pra pasta, trocar aparência do
   azulejo), cada um partindo do widget até o banco.
5. **[Vocabulário rápido](docs/05-vocabulario.md)** — glossário curto pra
   quando um termo específico travar a leitura.

Se você só quer destravar um conceito pontual, vá direto na parte
correspondente — cada arquivo linka pros outros quando precisa de contexto
extra.
