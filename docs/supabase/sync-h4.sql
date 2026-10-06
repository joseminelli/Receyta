-- Sync do resto (H4): calendário, listas de compras, histórico "cozinhei" e
-- despensa. Rodar no SQL Editor do Supabase DEPOIS do `sync.sql`.
-- Idempotente: pode rodar de novo sem erro.
--
-- Só amplia os tipos aceitos em `sync_docs.kind`. A tabela, as policies e o
-- trigger de "o mais recente vence" são os mesmos do `sync.sql`.
--
-- Tipos: recipe, folder (H3) e meal_plan, shopping_list, shopping_item,
-- cook_log, pantry (H4).

alter table public.sync_docs
  drop constraint if exists sync_docs_kind_check;

alter table public.sync_docs
  add constraint sync_docs_kind_check check (kind in (
    'recipe',
    'folder',
    'meal_plan',
    'shopping_list',
    'shopping_item',
    'cook_log',
    'pantry'
  ));
