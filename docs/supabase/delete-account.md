# Excluir minha conta — função do servidor

O botão **Excluir minha conta** (Configurações → Zona de risco) chama uma
função do Supabase, porque apagar um usuário exige a chave `service_role`, que
**nunca** pode ficar no app. O código está em
[`supabase/functions/delete-account/index.ts`](../../supabase/functions/delete-account/index.ts).

O que a função faz, nesta ordem, **só para quem está chamando** (o id vem do
token de login, não do corpo da requisição):

1. apaga todas as fotos da pasta do usuário no bucket `recipe-images`;
2. apaga os itens dele em `sync_docs`;
3. apaga o usuário de login (`auth.users`).

## Publicar

### Opção A — pelo painel (sem instalar nada)

1. Supabase → **Edge Functions** → **Deploy a new function** → **Via Editor**.
2. Nome da função: `delete-account` (exatamente).
3. Apague o código de exemplo e cole o conteúdo de `index.ts`.
4. **Deploy**.
5. Em **Settings** da função, deixe **Verify JWT** ligado (padrão): assim só
   quem está logado consegue chamar.

### Opção B — pela linha de comando

```
supabase login
supabase link --project-ref kcaqemuoncgijerlpvhi
supabase functions deploy delete-account
```

As variáveis `SUPABASE_URL`, `SUPABASE_ANON_KEY` e `SUPABASE_SERVICE_ROLE_KEY`
já existem no ambiente das funções — não precisa configurar nada.

## Testar

Com uma conta de teste (não a sua principal): entre no app, abra
Configurações → **Excluir minha conta**, digite **EXCLUIR** e confirme. Depois:

- **Authentication → Users**: o usuário sumiu;
- **Storage → recipe-images**: a pasta dele sumiu;
- o app volta para "sem conta" e as receitas do aparelho continuam lá.

## Google Play

A Play exige, para apps que criam conta, **excluir a conta dentro do app** (feito
aqui) **e** um endereço na web onde a pessoa possa pedir a exclusão sem ter o
app instalado. Esse endereço é preenchido no Console da Play (Segurança dos
dados). Uma página simples com as instruções e um e-mail de contato atende.
Confira as regras atuais no Console antes de publicar.
