-- Link curto de receita: `https://receyta.whisklinestudio.com/r/<token>`.
-- Rodar no SQL Editor do Supabase. Idempotente: pode rodar de novo sem erro.
--
-- Guarda só o texto que o app já monta pro link longo (JSON compacto, gzip e
-- base64url), sem foto. Quem cria precisa estar logado (até 20 por dia); quem
-- lê não precisa de login, só do token. Vale 30 dias.
--
-- A tabela não tem policy: só as funções (security definer) mexem nela.

create table if not exists public.shared_recipe_links (
  token      text        primary key,
  created_by uuid        not null default auth.uid()
                         references auth.users (id) on delete cascade,
  data       text        not null check (char_length(data) between 1 and 12000),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null
);

create index if not exists shared_recipe_links_owner_idx
  on public.shared_recipe_links (created_by, created_at);

alter table public.shared_recipe_links enable row level security;

-- Cria o link e devolve o token (10 caracteres).
create or replace function public.create_recipe_link(p_data text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_token text;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;
  if p_data is null or char_length(p_data) = 0 then
    raise exception 'empty_data';
  end if;
  delete from shared_recipe_links where expires_at < now();
  if (
    select count(*) from shared_recipe_links
    where created_by = auth.uid() and created_at > now() - interval '1 day'
  ) >= 20 then
    raise exception 'too_many_links';
  end if;
  loop
    v_token := substr(replace(gen_random_uuid()::text, '-', ''), 1, 10);
    exit when not exists (
      select 1 from shared_recipe_links where token = v_token
    );
  end loop;
  insert into shared_recipe_links (token, created_by, data, expires_at)
    values (v_token, auth.uid(), p_data, now() + interval '30 days');
  return v_token;
end;
$$;

-- Devolve o texto do link, ou nulo se o token não existe ou já venceu.
create or replace function public.get_recipe_link(p_token text)
returns text
language sql
security definer
stable
set search_path = public
as $$
  select data
  from shared_recipe_links
  where token = lower(trim(p_token)) and expires_at > now();
$$;

revoke all on function public.create_recipe_link(text) from public;
revoke all on function public.get_recipe_link(text)    from public;

grant execute on function public.create_recipe_link(text) to authenticated;
grant execute on function public.get_recipe_link(text)    to anon, authenticated;

-- Limpeza: as funções já apagam os vencidos ao criar, e este agendamento
-- (pg_cron, de hora em hora) cobre o caso de ninguém criar link. Se o pg_cron
-- não estiver disponível, só avisa e segue.

do $$
begin
  create extension if not exists pg_cron;
  perform cron.unschedule(jobid)
    from cron.job where jobname = 'receyta_limpa_links_receita';
  perform cron.schedule(
    'receyta_limpa_links_receita',
    '41 * * * *',
    $cron$delete from public.shared_recipe_links where expires_at < now()$cron$
  );
exception when others then
  raise notice 'pg_cron indisponível, limpeza só pelas funções: %', sqlerrm;
end $$;
