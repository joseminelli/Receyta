-- Bucket privado das fotos de receita (H0). Rodar no SQL Editor do Supabase.
-- Idempotente: pode rodar de novo sem erro.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('recipe-images', 'recipe-images', false, 1048576, array['image/jpeg'])
on conflict (id) do update
  set public = false,
      file_size_limit = 1048576,
      allowed_mime_types = array['image/jpeg'];

drop policy if exists "recipe images: read own" on storage.objects;
drop policy if exists "recipe images: insert own" on storage.objects;
drop policy if exists "recipe images: update own" on storage.objects;
drop policy if exists "recipe images: delete own" on storage.objects;

-- Cada usuário só enxerga e mexe na pasta <seu-id>/...
create policy "recipe images: read own"
on storage.objects for select to authenticated
using (bucket_id = 'recipe-images'
       and (storage.foldername(name))[1] = auth.uid()::text);

create policy "recipe images: insert own"
on storage.objects for insert to authenticated
with check (bucket_id = 'recipe-images'
            and (storage.foldername(name))[1] = auth.uid()::text);

create policy "recipe images: update own"
on storage.objects for update to authenticated
using (bucket_id = 'recipe-images'
       and (storage.foldername(name))[1] = auth.uid()::text);

create policy "recipe images: delete own"
on storage.objects for delete to authenticated
using (bucket_id = 'recipe-images'
       and (storage.foldername(name))[1] = auth.uid()::text);
