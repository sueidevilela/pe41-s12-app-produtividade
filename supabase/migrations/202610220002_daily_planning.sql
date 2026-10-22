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
commit;
