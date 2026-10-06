-- Teto de fotos por conta (30 MB). Rodar no SQL Editor do Supabase DEPOIS do
-- `recipe-images.sql`. Idempotente: pode rodar de novo sem erro.
--
-- A regra mora no servidor (o app pode estar desatualizado ou ser contornado).
-- Passou do teto: o envio de foto nova é recusado e o app guarda a foto só no
-- aparelho. Pra mudar o teto, troque o número em `photo_quota_bytes()` e rode
-- este arquivo de novo — o app lê o valor daqui, não tem número fixo lá.

-- O teto, em bytes (30 MB = 30 * 1024 * 1024).
create or replace function public.photo_quota_bytes()
returns bigint
language sql
immutable
as $$ select 31457280::bigint $$;

-- Quanto a conta de quem chama já usa de fotos. `security definer` porque quem
-- chama não pode ler `storage.objects` direto; a função só soma a PRÓPRIA
-- pasta (`auth.uid()`), então não vaza nada de outra conta.
create or replace function public.photo_usage_bytes()
returns bigint
language sql
stable
security definer
set search_path = public, storage
as $$
  select coalesce(sum((metadata ->> 'size')::bigint), 0)::bigint
  from storage.objects
  where bucket_id = 'recipe-images'
    and (storage.foldername(name))[1] = auth.uid()::text
$$;

revoke all on function public.photo_usage_bytes() from public;
grant execute on function public.photo_usage_bytes() to authenticated;
grant execute on function public.photo_quota_bytes() to authenticated;

-- Envio de foto nova: só enquanto a conta está abaixo do teto. Pode passar
-- um pouco com a última foto (no máximo o limite de 1 MB por arquivo do
-- bucket), porque o tamanho da foto que está entrando ainda não é conhecido.
drop policy if exists "recipe images: insert own" on storage.objects;

create policy "recipe images: insert own"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'recipe-images'
  and (storage.foldername(name))[1] = auth.uid()::text
  and public.photo_usage_bytes() < public.photo_quota_bytes()
);
