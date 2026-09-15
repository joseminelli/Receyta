# Vocabulário rápido

> Parte 5 de 7 do guia técnico. [Índice](../arquitetura-e-fluxo.md) ·
> anterior: [Exemplos reais na View](04-exemplos-na-view.md).

Pra quem está enferrujado e só quer destravar um termo específico:

- **DTO** — no plano (§5) é mencionado como camada entre Repository e
  remoto; hoje, sem bloco H, o Repository conversa direto com `RecipeRow`
  (a "linha" gerada pelo Drift) fazendo as vezes de DTO local.
  Um DTO de verdade (JSON do backend) só aparece no bloco H.
- **Stream vs. Future** — `Future<T>` resolve uma vez; `Stream<T>` pode emitir
  vários valores ao longo do tempo. Toda leitura que a UI precisa manter
  atualizada (lista de receitas, detalhe de uma receita) é `Stream`; toda
  operação pontual (salvar, favoritar, apagar) é `Future<Result<T>>`.
- **Migração** — script que transforma o schema da versão N para N+1 sem
  apagar dado existente do usuário já instalado (ver
  [migrações](02-banco-local.md#migrações--como-o-schema-evolui-sem-perder-dado-do-usuário)).
- **Soft delete** — "apagar" que só marca `deletedAt`, permitindo desfazer
  dentro do prazo (30 dias, RF-01.6); `hardDelete` é o apagar de verdade.
- **Offline-first** — não é "funciona offline também"; é "o dispositivo é a
  fonte de verdade primária SEMPRE", e qualquer sync futuro é uma camada por
  cima que reconcilia, nunca um pré-requisito para a operação funcionar.

---

**Próximo:** [O motor de ingredientes](06-motor-de-ingredientes.md) — parser,
normalizador, catálogo e fuzzy match (bloco C).
