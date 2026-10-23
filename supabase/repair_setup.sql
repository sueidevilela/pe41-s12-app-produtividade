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

commit;
