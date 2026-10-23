begin;
alter table public.tarefas add column if not exists recorrencia text check(recorrencia in('semanal','mensal','anual'));
-- Preservar as séries semanais existentes.
update public.tarefas set recorrencia='semanal' where recorrente_semanal and recorrencia is null;
create or replace function public.sincronizar_recorrencia() returns trigger language plpgsql set search_path='' as $$
begin
 if TG_OP='INSERT' then
  if NEW.recorrencia is null and NEW.recorrente_semanal then NEW.recorrencia:='semanal'; end if;
 elsif NEW.recorrencia is not distinct from OLD.recorrencia and NEW.recorrente_semanal is distinct from OLD.recorrente_semanal then
  NEW.recorrencia:=case when NEW.recorrente_semanal then 'semanal' else null end;
 end if;
 NEW.recorrente_semanal:=coalesce(NEW.recorrencia='semanal',false);
 return NEW;
end $$;
drop trigger if exists a_sincronizar_recorrencia on public.tarefas;
create trigger a_sincronizar_recorrencia before insert or update on public.tarefas for each row execute function public.sincronizar_recorrencia();
do $$ begin
 if not exists(select 1 from pg_constraint where conrelid='public.tarefas'::regclass and conname='recorrencia_definida') then
  alter table public.tarefas add constraint recorrencia_definida check(recorrencia is null or (prazo is not null and not concluida));
 end if;
end $$;
create or replace function public.data_recorrente_valida(inicio date, dia date, tipo text) returns boolean language plpgsql immutable set search_path='' as $$
declare limite integer; esperado integer;
begin
 if inicio is null or dia is null or tipo is null or dia<inicio then return false; end if;
 if tipo='semanal' then return (dia-inicio)%7=0; end if;
 limite:=extract(day from (date_trunc('month',dia::timestamp)+interval '1 month'-interval '1 day'))::integer;
 esperado:=least(extract(day from inicio)::integer,limite);
 if tipo='mensal' then return extract(day from dia)::integer=esperado; end if;
 if tipo='anual' then return extract(month from dia)=extract(month from inicio) and extract(day from dia)::integer=esperado; end if;
 return false;
end $$;
-- Mantém o nome da função para atualizar o trigger instalado na migration anterior.
create or replace function public.validar_ocorrencia_semanal() returns trigger language plpgsql set search_path='' as $$
declare t public.tarefas;
begin
 select * into t from public.tarefas where id=NEW.tarefa_id and user_id=NEW.user_id;
 if not found then raise exception 'Tarefa indisponível para sua conta.'; end if;
 if TG_OP='INSERT' then
  if not exists(select 1 from public.tarefa_ocorrencias r where r.user_id=NEW.user_id and r.tarefa_id=NEW.tarefa_id and r.data=NEW.data) and not public.data_recorrente_valida(t.prazo,NEW.data,t.recorrencia) then raise exception 'Esta data não corresponde à recorrência da tarefa.'; end if;
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
notify pgrst,'reload schema';
commit;
