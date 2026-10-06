-- Sync de receitas e pastas pela conta (H3). Rodar no SQL Editor do Supabase.
-- Idempotente: pode rodar de novo sem erro.
--
-- Uma linha por item sincronizado (receita ou pasta), com o corpo em JSON.
-- 'recipe' e 'folder' aqui; os demais tipos (calendário, listas, histórico,
-- despensa) entram com o `sync-h4.sql`, que amplia o `check` de `kind`.

create table if not exists public.sync_docs (
  user_id    uuid        not null default auth.uid()
                         references auth.users (id) on delete cascade,
  kind       text        not null check (kind in ('recipe', 'folder')),
  id         text        not null,
  -- Corpo do item. Nulo quando `deleted` (só o aviso de exclusão fica).
  data       jsonb,
  deleted    boolean     not null default false,
  -- Quando o item foi editado de verdade (relógio do aparelho): desempata
  -- conflito, vence o mais recente.
  edited_at  timestamptz not null,
  -- Relógio do SERVIDOR na gravação: é o cursor de leitura dos aparelhos.
  updated_at timestamptz not null default now(),
  primary key (user_id, kind, id)
);

create index if not exists sync_docs_cursor
  on public.sync_docs (user_id, updated_at, kind, id);

alter table public.sync_docs enable row level security;

drop policy if exists "sync_docs: select own" on public.sync_docs;
drop policy if exists "sync_docs: insert own" on public.sync_docs;
drop policy if exists "sync_docs: update own" on public.sync_docs;
drop policy if exists "sync_docs: delete own" on public.sync_docs;

-- Cada usuário só enxerga e mexe nas próprias linhas.
create policy "sync_docs: select own" on public.sync_docs
  for select to authenticated using (user_id = auth.uid());

create policy "sync_docs: insert own" on public.sync_docs
  for insert to authenticated with check (user_id = auth.uid());

create policy "sync_docs: update own" on public.sync_docs
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "sync_docs: delete own" on public.sync_docs
  for delete to authenticated using (user_id = auth.uid());

-- Proteção no servidor: um aparelho com versão velha do item não sobrescreve
-- uma edição mais nova. Se `edited_at` chegar menor que o gravado, a
-- atualização é descartada em silêncio. Senão, carimba `updated_at` com o
-- relógio do servidor.
create or replace function public.sync_docs_guard()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'UPDATE' and new.edited_at < old.edited_at then
    return null;
  end if;
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists sync_docs_guard on public.sync_docs;
create trigger sync_docs_guard
  before insert or update on public.sync_docs
  for each row execute function public.sync_docs_guard();
