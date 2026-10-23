begin;
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
