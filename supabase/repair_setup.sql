-- Atualiza um projeto que ja possui a migration inicial. Pode ser repetido.
-- Nao apaga registros, nao troca donos e nao altera as politicas de tarefas.
begin;

-- NULL preserva o significado: esforço e dia de conclusão antigos são desconhecidos.
alter table public.tarefas add column if not exists esforco text check (esforco in ('baixo','medio','alto'));
alter table public.tarefas add column if not exists concluida_em timestamptz;
alter table public.tarefas alter column concluida_em set default now();
create or replace function public.registrar_conclusao_tarefa()
returns trigger language plpgsql set search_path = '' as $$
begin
 if TG_OP = 'INSERT' then
  if not NEW.concluida then NEW.concluida_em := null; end if;
  -- NULL explicito em importacoes preserva conclusoes antigas sem data conhecida.
 elsif NEW.concluida and not OLD.concluida then NEW.concluida_em := now();
 elsif not NEW.concluida then NEW.concluida_em := null;
 else NEW.concluida_em := OLD.concluida_em;
 end if;
 return NEW;
end;
$$;
drop trigger if exists registrar_conclusao on public.tarefas;
create trigger registrar_conclusao before insert or update on public.tarefas for each row execute function public.registrar_conclusao_tarefa();
-- RLS e user_id existentes continuam obrigatórios. Não inferir datas antigas.


alter table public.tarefas add column if not exists proximo_passo text check (length(proximo_passo)<=500);
alter table public.tarefas add column if not exists plano_se_entao text check (length(plano_se_entao)<=500);
-- Anotações privadas: continuam protegidas pelas políticas user_id existentes.


create table if not exists public.projetos (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 titulo text not null check(length(trim(titulo)) between 1 and 120),
 created_at timestamptz not null default now(), unique(id,user_id)
);
create table if not exists public.compromissos (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 titulo text not null check(length(trim(titulo)) between 1 and 200),
 inicio timestamptz not null, fim timestamptz not null check(fim>inicio)
);
alter table public.tarefas add column if not exists projeto_id uuid;
alter table public.tarefas add column if not exists etapa text not null default 'planejado' check(etapa in ('planejado','andamento'));
do $$ begin
 if not exists(select 1 from pg_constraint where conrelid='public.tarefas'::regclass and conname='tarefas_projeto_dono') then
  alter table public.tarefas add constraint tarefas_projeto_dono foreign key(projeto_id,user_id) references public.projetos(id,user_id);
 end if;
end $$;
alter table public.projetos enable row level security;
alter table public.compromissos enable row level security;
revoke all on public.projetos,public.compromissos from anon,public;
grant select,insert,update,delete on public.projetos,public.compromissos to authenticated;
drop policy if exists projetos_pessoais on public.projetos;
create policy projetos_pessoais on public.projetos for all to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
drop policy if exists compromissos_pessoais on public.compromissos;
create policy compromissos_pessoais on public.compromissos for all to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
create index if not exists projetos_dono on public.projetos(user_id);
create index if not exists compromissos_dono_inicio on public.compromissos(user_id,inicio);
do $$ declare t text; begin
 foreach t in array array['projetos','compromissos'] loop
  if exists(select 1 from pg_publication where pubname='supabase_realtime') and not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename=t) then
   execute format('alter publication supabase_realtime add table public.%I',t);
  end if;
 end loop;
end $$;


alter table public.compromissos add column if not exists projeto_id uuid;
do $$ begin
 if not exists(select 1 from pg_constraint where conrelid='public.compromissos'::regclass and conname='compromissos_projeto_dono') then
  alter table public.compromissos add constraint compromissos_projeto_dono foreign key(projeto_id,user_id) references public.projetos(id,user_id);
 end if;
end $$;
create index if not exists compromissos_projeto on public.compromissos(projeto_id);
notify pgrst, 'reload schema';





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




alter table public.tarefas add column if not exists recorrente_semanal boolean not null default false;
do $$ begin
 if not exists(select 1 from pg_constraint where conrelid='public.tarefas'::regclass and conname='tarefas_id_dono_unique') then
  alter table public.tarefas add constraint tarefas_id_dono_unique unique(id,user_id);
 end if;
 if not exists(select 1 from pg_constraint where conrelid='public.tarefas'::regclass and conname='recorrencia_com_data') then
  alter table public.tarefas add constraint recorrencia_com_data check(not recorrente_semanal or (prazo is not null and not concluida));
 end if;
end $$;
create table if not exists public.tarefa_ocorrencias (
 id uuid primary key default gen_random_uuid(),user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 tarefa_id uuid not null, data date not null, concluida boolean not null default false,concluida_em timestamptz,
 unique(user_id,tarefa_id,data),foreign key(tarefa_id,user_id) references public.tarefas(id,user_id) on delete cascade
);
alter table public.tarefa_ocorrencias enable row level security;
revoke all on public.tarefa_ocorrencias from anon,public;
grant select,insert,update,delete on public.tarefa_ocorrencias to authenticated;
drop policy if exists ocorrencias_pessoais on public.tarefa_ocorrencias;
create policy ocorrencias_pessoais on public.tarefa_ocorrencias for all to authenticated using((select auth.uid())=user_id) with check((select auth.uid())=user_id);
create or replace function public.validar_ocorrencia_semanal() returns trigger language plpgsql set search_path='' as $$
declare t public.tarefas;
begin
 select * into t from public.tarefas where id=NEW.tarefa_id and user_id=NEW.user_id;
 if not found then raise exception 'Tarefa indisponível para sua conta.'; end if;
 if TG_OP='INSERT' then
  if not exists(select 1 from public.tarefa_ocorrencias r where r.user_id=NEW.user_id and r.tarefa_id=NEW.tarefa_id and r.data=NEW.data) and (not t.recorrente_semanal or t.prazo is null or NEW.data<t.prazo or (NEW.data-t.prazo)%7<>0) then raise exception 'Esta data não corresponde à recorrência semanal.'; end if;
 else
  if NEW.tarefa_id<>OLD.tarefa_id or NEW.data<>OLD.data or NEW.user_id<>OLD.user_id then raise exception 'A data e o dono da ocorrência não podem ser alterados.'; end if;
 end if;
 if not NEW.concluida then NEW.concluida_em:=null;
 elsif TG_OP='INSERT' then NEW.concluida_em:=now();
 elsif not OLD.concluida then NEW.concluida_em:=now();
 else NEW.concluida_em:=OLD.concluida_em;
 end if;
 return NEW;
end $$;
drop trigger if exists validar_ocorrencia on public.tarefa_ocorrencias;
create trigger validar_ocorrencia before insert or update on public.tarefa_ocorrencias for each row execute function public.validar_ocorrencia_semanal();
do $$ begin
 if exists(select 1 from pg_publication where pubname='supabase_realtime') and not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='tarefa_ocorrencias') then
  alter publication supabase_realtime add table public.tarefa_ocorrencias;
 end if;
end $$;
notify pgrst,'reload schema';

commit;
