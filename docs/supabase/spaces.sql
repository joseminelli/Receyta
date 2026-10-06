-- Casa: um espaço compartilhado entre pessoas (lista de compras e calendário).
-- Rodar no SQL Editor do Supabase DEPOIS do `sync.sql` e do `sync-h4.sql`.
-- Idempotente: pode rodar de novo sem erro.
--
-- Modelo
--   spaces         a casa (um dono).
--   space_members  quem faz parte (no máximo 6; cada pessoa em UMA casa só).
--   space_invites  códigos de convite: 8 caracteres, uso único, valem 48 h.
--   shared_docs    os itens compartilhados (lista, item de lista, refeição,
--                  receita do calendário), no mesmo formato do `sync_docs`,
--                  mas da casa e não de uma pessoa.
--
-- Criar casa, convidar, entrar, sair e remover alguém são FUNÇÕES (abaixo):
-- as tabelas não aceitam escrita direta, só leitura de quem é da casa. Assim
-- ninguém entra sem um convite válido nem se promove a dono.

-- ---------------------------------------------------------------- tabelas

create table if not exists public.spaces (
  id         uuid        primary key default gen_random_uuid(),
  owner_id   uuid        not null default auth.uid()
                         references auth.users (id) on delete cascade,
  name       text        not null default 'Casa'
                         check (char_length(name) between 1 and 60),
  created_at timestamptz not null default now()
);

create table if not exists public.space_members (
  space_id     uuid        not null
                           references public.spaces (id) on delete cascade,
  user_id      uuid        not null
                           references auth.users (id) on delete cascade,
  role         text        not null check (role in ('owner', 'member')),
  display_name text        not null default ''
                           check (char_length(display_name) <= 60),
  joined_at    timestamptz not null default now(),
  primary key (space_id, user_id)
);

-- Cada pessoa participa de uma casa só.
create unique index if not exists space_members_one_space
  on public.space_members (user_id);

create table if not exists public.space_invites (
  code       text        primary key,
  space_id   uuid        not null
                         references public.spaces (id) on delete cascade,
  created_by uuid        not null default auth.uid()
                         references auth.users (id) on delete cascade,
  expires_at timestamptz not null
);

create table if not exists public.shared_docs (
  space_id   uuid        not null
                         references public.spaces (id) on delete cascade,
  kind       text        not null
                         check (kind in ('shopping_list', 'shopping_item',
                                         'meal_plan', 'recipe')),
  id         text        not null,
  data       jsonb,
  deleted    boolean     not null default false,
  edited_at  timestamptz not null,
  updated_at timestamptz not null default now(),
  primary key (space_id, kind, id)
);

create index if not exists shared_docs_cursor
  on public.shared_docs (space_id, updated_at, kind, id);

-- ------------------------------------------------------------ segurança

alter table public.spaces        enable row level security;
alter table public.space_members enable row level security;
alter table public.space_invites enable row level security;
alter table public.shared_docs   enable row level security;

-- "Sou da casa X?" — `security definer` pra não cair em recursão de policy.
create or replace function public.is_space_member(p_space uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.space_members
    where space_id = p_space and user_id = auth.uid()
  );
$$;

drop policy if exists "spaces: select member" on public.spaces;
create policy "spaces: select member" on public.spaces
  for select to authenticated using (public.is_space_member(id));

drop policy if exists "space_members: select member" on public.space_members;
create policy "space_members: select member" on public.space_members
  for select to authenticated using (public.is_space_member(space_id));

-- `space_invites` não tem policy: só as funções (security definer) mexem.

drop policy if exists "shared_docs: select member" on public.shared_docs;
drop policy if exists "shared_docs: insert member" on public.shared_docs;
drop policy if exists "shared_docs: update member" on public.shared_docs;
drop policy if exists "shared_docs: delete member" on public.shared_docs;

create policy "shared_docs: select member" on public.shared_docs
  for select to authenticated using (public.is_space_member(space_id));

create policy "shared_docs: insert member" on public.shared_docs
  for insert to authenticated with check (public.is_space_member(space_id));

create policy "shared_docs: update member" on public.shared_docs
  for update to authenticated
  using (public.is_space_member(space_id))
  with check (public.is_space_member(space_id));

create policy "shared_docs: delete member" on public.shared_docs
  for delete to authenticated using (public.is_space_member(space_id));

-- Mesma regra do `sync_docs`: a edição mais nova vence; o servidor carimba
-- `updated_at` (o cursor de leitura dos aparelhos).
create or replace function public.shared_docs_guard()
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

drop trigger if exists shared_docs_guard on public.shared_docs;
create trigger shared_docs_guard
  before insert or update on public.shared_docs
  for each row execute function public.shared_docs_guard();

-- ---------------------------------------------------------------- funções

-- Cria a casa e coloca quem chamou como dono. Devolve o id.
create or replace function public.create_space(p_display_name text default '')
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_space uuid;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;
  if exists (select 1 from space_members where user_id = auth.uid()) then
    raise exception 'already_in_space';
  end if;
  insert into spaces (owner_id) values (auth.uid()) returning id into v_space;
  insert into space_members (space_id, user_id, role, display_name)
    values (v_space, auth.uid(), 'owner', left(coalesce(p_display_name, ''), 60));
  return v_space;
end;
$$;

-- Gera um código de convite (só o dono). Uso único, vale 48 h.
create or replace function public.create_invite()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_space uuid;
  v_code  text;
begin
  select space_id into v_space
    from space_members
    where user_id = auth.uid() and role = 'owner';
  if v_space is null then
    raise exception 'not_owner';
  end if;
  delete from space_invites where expires_at < now();
  if (select count(*) from space_invites where space_id = v_space) >= 5 then
    raise exception 'too_many_invites';
  end if;
  loop
    v_code := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
    exit when not exists (select 1 from space_invites where code = v_code);
  end loop;
  insert into space_invites (code, space_id, created_by, expires_at)
    values (v_code, v_space, auth.uid(), now() + interval '48 hours');
  return v_code;
end;
$$;

-- Entra numa casa com um código. Devolve o id da casa.
create or replace function public.join_space(
  p_code text,
  p_display_name text default ''
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_space uuid;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;
  if exists (select 1 from space_members where user_id = auth.uid()) then
    raise exception 'already_in_space';
  end if;
  delete from space_invites where expires_at < now();
  select space_id into v_space
    from space_invites
    where code = upper(trim(p_code)) and expires_at > now();
  if v_space is null then
    raise exception 'invalid_invite';
  end if;
  if (select count(*) from space_members where space_id = v_space) >= 6 then
    raise exception 'space_full';
  end if;
  insert into space_members (space_id, user_id, role, display_name)
    values (v_space, auth.uid(), 'member', left(coalesce(p_display_name, ''), 60));
  delete from space_invites where code = upper(trim(p_code));
  return v_space;
end;
$$;

-- Sai da casa. Se quem sai é o dono, a casa e tudo o que ela guarda na nuvem
-- são apagados (cada pessoa fica com a cópia que já tem no aparelho).
create or replace function public.leave_space()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_space uuid;
  v_role  text;
begin
  select space_id, role into v_space, v_role
    from space_members where user_id = auth.uid();
  if v_space is null then
    return;
  end if;
  if v_role = 'owner' then
    delete from spaces where id = v_space;
  else
    delete from space_members
      where space_id = v_space and user_id = auth.uid();
  end if;
end;
$$;

-- O dono tira alguém da casa.
create or replace function public.remove_member(p_user uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_space uuid;
begin
  select space_id into v_space
    from space_members
    where user_id = auth.uid() and role = 'owner';
  if v_space is null then
    raise exception 'not_owner';
  end if;
  if p_user = auth.uid() then
    raise exception 'cannot_remove_owner';
  end if;
  delete from space_members where space_id = v_space and user_id = p_user;
end;
$$;

-- A casa de quem chamou e as pessoas dela (ou nulo).
create or replace function public.my_space()
returns jsonb
language sql
security definer
stable
set search_path = public
as $$
  select jsonb_build_object(
    'id', s.id,
    'name', s.name,
    'owner_id', s.owner_id,
    'members', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'user_id', m.user_id,
        'display_name', m.display_name,
        'role', m.role
      ) order by m.joined_at), '[]'::jsonb)
      from space_members m where m.space_id = s.id
    )
  )
  from space_members me
  join spaces s on s.id = me.space_id
  where me.user_id = auth.uid();
$$;

revoke all on function public.create_space(text)        from public;
revoke all on function public.create_invite()           from public;
revoke all on function public.join_space(text, text)    from public;
revoke all on function public.leave_space()             from public;
revoke all on function public.remove_member(uuid)       from public;
revoke all on function public.my_space()                from public;
revoke all on function public.is_space_member(uuid)     from public;

grant execute on function public.create_space(text)     to authenticated;
grant execute on function public.create_invite()        to authenticated;
grant execute on function public.join_space(text, text) to authenticated;
grant execute on function public.leave_space()          to authenticated;
grant execute on function public.remove_member(uuid)    to authenticated;
grant execute on function public.my_space()             to authenticated;
grant execute on function public.is_space_member(uuid) to authenticated;

-- ---------------------------------------------------------------- Realtime
-- Um aparelho avisa o outro na hora. As policies acima valem aqui também:
-- cada pessoa só recebe o aviso do que a casa dela guarda.

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public'
      and tablename = 'shared_docs'
  ) then
    alter publication supabase_realtime add table public.shared_docs;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public'
      and tablename = 'space_members'
  ) then
    alter publication supabase_realtime add table public.space_members;
  end if;
end $$;

-- ------------------------------------------------------- limpeza de convites
-- Convite vencido já não vale (as funções ignoram), mas a linha ficaria lá.
-- As funções acima apagam os vencidos sempre que alguém gera ou usa um convite;
-- este agendamento (pg_cron, de hora em hora) cobre o caso de ninguém mexer.
-- Se o pg_cron não estiver disponível no projeto, só avisa e segue — não é
-- obrigatório.

do $$
begin
  create extension if not exists pg_cron;
  perform cron.unschedule(jobid)
    from cron.job where jobname = 'receyta_limpa_convites';
  perform cron.schedule(
    'receyta_limpa_convites',
    '17 * * * *',
    $cron$delete from public.space_invites where expires_at < now()$cron$
  );
exception when others then
  raise notice 'pg_cron indisponível, limpeza só pelas funções: %', sqlerrm;
end $$;

-- ------------------------------------------------- Realtime da própria conta
-- Os aparelhos da MESMA pessoa também se avisam na hora: liga `sync_docs` ao
-- Realtime (a policy do `sync.sql` já limita cada um às próprias linhas).

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public'
      and tablename = 'sync_docs'
  ) then
    alter publication supabase_realtime add table public.sync_docs;
  end if;
end $$;
