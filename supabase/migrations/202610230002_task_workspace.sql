begin;
alter table public.tarefas add column if not exists descricao text check(length(descricao)<=10000);
alter table public.tarefas add column if not exists etiquetas text[] not null default '{}';
alter table public.tarefas add column if not exists subtarefas jsonb not null default '[]'::jsonb;
alter table public.tarefas add column if not exists secao text;
-- Não atribuir uma data fictícia de modificação aos registros anteriores.
alter table public.tarefas add column if not exists updated_at timestamptz;
alter table public.projetos add column if not exists favorito boolean not null default false;
create or replace function public.validar_detalhes_tarefa() returns trigger language plpgsql set search_path='' as $$
declare s jsonb; tag text;
begin
 if jsonb_typeof(NEW.subtarefas) <> 'array' or jsonb_array_length(NEW.subtarefas)>200 then raise exception 'Use até 200 subtarefas.'; end if;
 for s in select * from jsonb_array_elements(NEW.subtarefas) loop
  if jsonb_typeof(s)<>'object' or jsonb_typeof(s->'id') is distinct from 'string' or jsonb_typeof(s->'titulo') is distinct from 'string' or jsonb_typeof(s->'concluida') is distinct from 'boolean' or length(trim(s->>'titulo')) not between 1 and 200 then raise exception 'Subtarefa inválida.'; end if;
 end loop;
 if cardinality(NEW.etiquetas)>20 then raise exception 'Use até 20 etiquetas.'; end if;
 foreach tag in array NEW.etiquetas loop
  if tag is null or length(trim(tag)) not between 1 and 40 then raise exception 'Etiqueta inválida.'; end if;
 end loop;
 NEW.updated_at := now();
 if TG_OP='UPDATE' then NEW.created_at:=OLD.created_at; end if;
 return NEW;
end $$;
drop trigger if exists validar_detalhes on public.tarefas;
create trigger validar_detalhes before insert or update on public.tarefas for each row execute function public.validar_detalhes_tarefa();
create table if not exists public.tarefa_secoes (
 id uuid primary key default gen_random_uuid(),user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 titulo text not null check(length(trim(titulo)) between 1 and 80)
);
create table if not exists public.aniversarios (
 id uuid primary key default gen_random_uuid(),user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 nome text not null check(length(trim(nome)) between 1 and 120),
 dia smallint not null, mes smallint not null check(mes between 1 and 12),
 check(dia between 1 and case when mes=2 then 29 when mes in(4,6,9,11) then 30 else 31 end)
);
alter table public.tarefa_secoes enable row level security;
alter table public.aniversarios enable row level security;
revoke all on public.tarefa_secoes,public.aniversarios from anon,public;
grant select,insert,update,delete on public.tarefa_secoes,public.aniversarios to authenticated;
drop policy if exists secoes_pessoais on public.tarefa_secoes;
create policy secoes_pessoais on public.tarefa_secoes for all to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
drop policy if exists aniversarios_pessoais on public.aniversarios;
create policy aniversarios_pessoais on public.aniversarios for all to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
create index if not exists aniversarios_dono on public.aniversarios(user_id);
create index if not exists secoes_dono on public.tarefa_secoes(user_id);
insert into storage.buckets(id,name,public,file_size_limit) values('anexos-tarefas','anexos-tarefas',false,10485760)
on conflict(id) do update set public=false,file_size_limit=10485760;
-- Arquivos privados: dono da pasta E dono da tarefa precisam coincidir.
drop policy if exists anexos_tarefas_pessoais on storage.objects;
create policy anexos_tarefas_pessoais on storage.objects for all to authenticated
using(bucket_id='anexos-tarefas' and (storage.foldername(name))[1]=(select auth.uid())::text and exists(select 1 from public.tarefas t where t.id::text=(storage.foldername(name))[2] and t.user_id=(select auth.uid())))
with check(bucket_id='anexos-tarefas' and (storage.foldername(name))[1]=(select auth.uid())::text and exists(select 1 from public.tarefas t where t.id::text=(storage.foldername(name))[2] and t.user_id=(select auth.uid())));
drop policy if exists anexos_tarefas_limite on storage.objects;
create policy anexos_tarefas_limite on storage.objects as restrictive for all to authenticated
using(bucket_id<>'anexos-tarefas' or ((storage.foldername(name))[1]=(select auth.uid())::text and exists(select 1 from public.tarefas t where t.id::text=(storage.foldername(name))[2] and t.user_id=(select auth.uid()))))
with check(bucket_id<>'anexos-tarefas' or ((storage.foldername(name))[1]=(select auth.uid())::text and exists(select 1 from public.tarefas t where t.id::text=(storage.foldername(name))[2] and t.user_id=(select auth.uid()))));
drop policy if exists anexos_tarefas_anon on storage.objects;
create policy anexos_tarefas_anon on storage.objects as restrictive for all to anon using(bucket_id<>'anexos-tarefas') with check(bucket_id<>'anexos-tarefas');
do $$ declare t text; begin
 foreach t in array array['tarefa_secoes','aniversarios'] loop
  if exists(select 1 from pg_publication where pubname='supabase_realtime') and not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename=t) then
   execute format('alter publication supabase_realtime add table public.%I',t);
  end if;
 end loop;
end $$;
notify pgrst,'reload schema';
commit;
