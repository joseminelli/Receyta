-- Assinatura (Receyta Plus): trava toda a parte online. Rodar no SQL Editor do
-- Supabase DEPOIS de `sync.sql`, `sync-h4.sql`, `spaces.sql`, `recipe-images.sql`
-- e `photo-quota.sql`. Idempotente: pode rodar de novo sem erro.
--
-- Importante: este arquivo REDEFINE policies e funções dos arquivos acima. Se
-- algum deles for rodado de novo depois, rode este por último outra vez.
--
-- Modelo
--   entitlements   uma linha por pessoa: até quando a assinatura da Google Play
--                  vale (`plan_until`, gravado pelo webhook do RevenueCat) e as
--                  liberações manuais (`grant_until` ou `lifetime`).
--   has_cloud_access()  "a pessoa que chamou tem a parte online?": assinatura
--                  própria, liberação manual ou casa cujo DONO tem acesso.
--
-- Quem não tem acesso não lê nem grava nada na nuvem. Nada é apagado: os dados
-- ficam no servidor e no aparelho, e tudo volta quando o acesso volta.

-- ---------------------------------------------------------------- tabela

create table if not exists public.entitlements (
  user_id       uuid        primary key
                            references auth.users (id) on delete cascade,
  -- Assinatura da Play (gravada só pelo webhook, com a chave service_role).
  plan_until    timestamptz,
  product_id    text,
  last_event_ms bigint      not null default 0,
  -- Liberação manual (feita por você, no SQL Editor).
  grant_until   timestamptz,
  lifetime      boolean     not null default false,
  note          text,
  updated_at    timestamptz not null default now()
);

alter table public.entitlements enable row level security;

drop policy if exists "entitlements: select own" on public.entitlements;
create policy "entitlements: select own" on public.entitlements
  for select to authenticated using (user_id = auth.uid());

-- ---------------------------------------------------------------- acesso

create or replace function public.user_has_own_access(p_user uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select coalesce((
    select e.lifetime
        or coalesce(e.plan_until  > now(), false)
        or coalesce(e.grant_until > now(), false)
    from public.entitlements e
    where e.user_id = p_user
  ), false);
$$;

-- Só as policies e as funções daqui usam: ninguém consulta o acesso dos outros.
revoke all on function public.user_has_own_access(uuid) from public;

-- Dono da casa com acesso próprio?
create or replace function public.space_owner_has_access(p_space uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select coalesce((
    select public.user_has_own_access(s.owner_id)
    from public.spaces s where s.id = p_space
  ), false);
$$;

revoke all on function public.space_owner_has_access(uuid) from public;

-- A pessoa que chamou tem a parte online? Própria, liberada ou pela casa.
create or replace function public.has_cloud_access()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select auth.uid() is not null and (
    public.user_has_own_access(auth.uid())
    or exists (
      select 1
      from public.space_members m
      where m.user_id = auth.uid()
        and public.space_owner_has_access(m.space_id)
    )
  );
$$;

revoke all on function public.has_cloud_access() from public;
grant execute on function public.has_cloud_access() to authenticated;

-- O que o app mostra: { active, source: none|own|grant|house, until }.
-- `until` nulo com `active` = sem prazo (liberação vitalícia).
create or replace function public.my_access()
returns jsonb
language plpgsql
security definer
stable
set search_path = public
as $$
declare
  v_me     uuid := auth.uid();
  v_e      public.entitlements;
  v_until  timestamptz;
  v_owner  public.entitlements;
begin
  if v_me is null then
    return jsonb_build_object('active', false, 'source', 'none', 'until', null);
  end if;

  select * into v_e from public.entitlements where user_id = v_me;
  if found then
    if v_e.lifetime then
      return jsonb_build_object('active', true, 'source', 'grant', 'until', null);
    end if;
    v_until := greatest(v_e.plan_until, v_e.grant_until);
    if v_until is not null and v_until > now() then
      return jsonb_build_object(
        'active', true,
        'source', case
          when v_e.plan_until is not null and v_e.plan_until > now()
            then 'own' else 'grant' end,
        'until', v_until
      );
    end if;
  end if;

  select e.* into v_owner
  from public.space_members m
  join public.spaces s on s.id = m.space_id
  join public.entitlements e on e.user_id = s.owner_id
  where m.user_id = v_me
    and public.user_has_own_access(s.owner_id)
  limit 1;
  if found then
    return jsonb_build_object(
      'active', true,
      'source', 'house',
      'until', case when v_owner.lifetime then null
                    else greatest(v_owner.plan_until, v_owner.grant_until) end
    );
  end if;

  return jsonb_build_object('active', false, 'source', 'none', 'until', null);
end;
$$;

revoke all on function public.my_access() from public;
grant execute on function public.my_access() to authenticated;

-- ---------------------------------------------------- liberação manual
-- Só roda no SQL Editor (papel postgres): ninguém do app chama.
--   select grant_access('amigo@gmail.com');                    -- vitalício
--   select grant_access('amigo@gmail.com', now() + interval '6 months');
--   select revoke_access('amigo@gmail.com');

create or replace function public.grant_access(
  p_email text,
  p_until timestamptz default null,
  p_note  text default null
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid;
begin
  select id into v_user from auth.users
    where lower(email) = lower(trim(p_email));
  if v_user is null then
    return 'Nenhuma conta com esse e-mail (a pessoa precisa ter entrado no app).';
  end if;
  insert into public.entitlements (user_id, grant_until, lifetime, note)
    values (v_user, p_until, p_until is null, p_note)
  on conflict (user_id) do update
    set grant_until = excluded.grant_until,
        lifetime    = excluded.lifetime,
        note        = coalesce(excluded.note, public.entitlements.note),
        updated_at  = now();
  return case when p_until is null then 'Liberado para sempre.'
              else 'Liberado até ' || p_until::text || '.' end;
end;
$$;

create or replace function public.revoke_access(p_email text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid;
begin
  select id into v_user from auth.users
    where lower(email) = lower(trim(p_email));
  if v_user is null then
    return 'Nenhuma conta com esse e-mail.';
  end if;
  update public.entitlements
    set grant_until = null, lifetime = false, updated_at = now()
    where user_id = v_user;
  return 'Liberação removida (a assinatura da Play, se houver, continua).';
end;
$$;

revoke all on function public.grant_access(text, timestamptz, text) from public, anon, authenticated;
revoke all on function public.revoke_access(text) from public, anon, authenticated;

-- ----------------------------------------------------- sync da conta

drop policy if exists "sync_docs: select own" on public.sync_docs;
drop policy if exists "sync_docs: insert own" on public.sync_docs;
drop policy if exists "sync_docs: update own" on public.sync_docs;
drop policy if exists "sync_docs: delete own" on public.sync_docs;

create policy "sync_docs: select own" on public.sync_docs
  for select to authenticated
  using (user_id = auth.uid() and public.has_cloud_access());

create policy "sync_docs: insert own" on public.sync_docs
  for insert to authenticated
  with check (user_id = auth.uid() and public.has_cloud_access());

create policy "sync_docs: update own" on public.sync_docs
  for update to authenticated
  using (user_id = auth.uid() and public.has_cloud_access())
  with check (user_id = auth.uid() and public.has_cloud_access());

create policy "sync_docs: delete own" on public.sync_docs
  for delete to authenticated
  using (user_id = auth.uid() and public.has_cloud_access());

-- ------------------------------------------------------- itens da casa

drop policy if exists "shared_docs: select member" on public.shared_docs;
drop policy if exists "shared_docs: insert member" on public.shared_docs;
drop policy if exists "shared_docs: update member" on public.shared_docs;
drop policy if exists "shared_docs: delete member" on public.shared_docs;

create policy "shared_docs: select member" on public.shared_docs
  for select to authenticated
  using (public.is_space_member(space_id) and public.has_cloud_access());

create policy "shared_docs: insert member" on public.shared_docs
  for insert to authenticated
  with check (public.is_space_member(space_id) and public.has_cloud_access());

create policy "shared_docs: update member" on public.shared_docs
  for update to authenticated
  using (public.is_space_member(space_id) and public.has_cloud_access())
  with check (public.is_space_member(space_id) and public.has_cloud_access());

create policy "shared_docs: delete member" on public.shared_docs
  for delete to authenticated
  using (public.is_space_member(space_id) and public.has_cloud_access());

-- ------------------------------------------------------- fotos (Storage)

drop policy if exists "recipe images: read own" on storage.objects;
drop policy if exists "recipe images: insert own" on storage.objects;
drop policy if exists "recipe images: update own" on storage.objects;
drop policy if exists "recipe images: delete own" on storage.objects;

create policy "recipe images: read own"
on storage.objects for select to authenticated
using (bucket_id = 'recipe-images'
       and (storage.foldername(name))[1] = auth.uid()::text
       and public.has_cloud_access());

create policy "recipe images: insert own"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'recipe-images'
  and (storage.foldername(name))[1] = auth.uid()::text
  and public.has_cloud_access()
  and public.photo_usage_bytes() < public.photo_quota_bytes()
);

create policy "recipe images: update own"
on storage.objects for update to authenticated
using (bucket_id = 'recipe-images'
       and (storage.foldername(name))[1] = auth.uid()::text
       and public.has_cloud_access());

create policy "recipe images: delete own"
on storage.objects for delete to authenticated
using (bucket_id = 'recipe-images'
       and (storage.foldername(name))[1] = auth.uid()::text
       and public.has_cloud_access());

-- ------------------------------------------------------------- a casa
-- Quem CRIA a casa precisa ter acesso próprio (é o dono que paga). Quem ENTRA
-- não precisa: usa a casa de graça enquanto o plano do dono estiver valendo.

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
  if not public.user_has_own_access(auth.uid()) then
    raise exception 'subscription_required';
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
  if not public.user_has_own_access(auth.uid()) then
    raise exception 'subscription_required';
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
  if not public.space_owner_has_access(v_space) then
    raise exception 'space_inactive';
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

revoke all on function public.create_space(text)     from public;
revoke all on function public.create_invite()        from public;
revoke all on function public.join_space(text, text) from public;
grant execute on function public.create_space(text)     to authenticated;
grant execute on function public.create_invite()        to authenticated;
grant execute on function public.join_space(text, text) to authenticated;
