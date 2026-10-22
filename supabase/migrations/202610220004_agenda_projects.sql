begin;
create table public.projetos (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 titulo text not null check(length(trim(titulo)) between 1 and 120),
 created_at timestamptz not null default now(), unique(id,user_id)
);
create table public.compromissos (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 titulo text not null check(length(trim(titulo)) between 1 and 200),
 inicio timestamptz not null, fim timestamptz not null check(fim>inicio)
);
alter table public.tarefas add column if not exists projeto_id uuid;
alter table public.tarefas add column if not exists etapa text not null default 'planejado' check(etapa in ('planejado','andamento'));
alter table public.tarefas add constraint tarefas_projeto_dono foreign key(projeto_id,user_id) references public.projetos(id,user_id);
alter table public.projetos enable row level security;
alter table public.compromissos enable row level security;
revoke all on public.projetos,public.compromissos from anon,public;
grant select,insert,update,delete on public.projetos,public.compromissos to authenticated;
create policy projetos_pessoais on public.projetos for all to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
create policy compromissos_pessoais on public.compromissos for all to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
create index projetos_dono on public.projetos(user_id);
create index compromissos_dono_inicio on public.compromissos(user_id,inicio);
alter publication supabase_realtime add table public.projetos,public.compromissos;
commit;
