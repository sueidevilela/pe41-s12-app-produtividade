-- Execute uma vez pelo SQL Editor ou com supabase db push.
begin;
create table public.tarefas (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 titulo text not null check(length(trim(titulo)) between 1 and 200),
 prioridade text not null default 'media' check(prioridade in ('alta','media','baixa')),
 prazo date, concluida boolean not null default false,
 created_at timestamptz not null default now()
);
create table public.habitos (
 id text primary key,
 titulo text not null, meta text not null,
 periodicidade text not null check(periodicidade in ('diaria','semanal')),
 icone text
);
insert into public.habitos values
 ('agua','Beber água','2,5 litros','diaria','◉'),
 ('leitura','Leitura','20 minutos','diaria','▤'),
 ('exercicio','Exercícios','5 vezes por semana','semanal','↗'),
 ('meditacao','Meditação','Diariamente','diaria','✧'),
 ('agenda','Revisar agenda','Diariamente','diaria','▦');
create table public.habitos_registros (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 habito text not null references public.habitos(id),
 data date not null, concluido boolean not null default false,
 unique(user_id,habito,data)
);
create table public.sessoes_foco (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 duracao_minutos integer not null check(duracao_minutos between 1 and 180),
 segundos_realizados integer not null check(segundos_realizados between 0 and 10800),
 concluida boolean not null default false,
 finalizada_em timestamptz not null default now()
);
create table public.biblioteca (
 id text primary key, titulo text not null, categoria text not null,
 descricao text not null, url text not null check(url like 'https://%'), icone text
);
insert into public.biblioteca values
 ('habitos','Pequenos hábitos, grandes mudanças','Hábitos','Construa uma rotina com pequenos passos consistentes.','https://jamesclear.com/habits','✿'),
 ('produtividade','Faça espaço para o que importa','Produtividade','Conheça o método GTD e organize suas próximas ações.','https://gettingthingsdone.com/what-is-gtd/','↗'),
 ('organizacao','Uma mente mais organizada','Organização','Ideias práticas para cuidar da sua rotina e do seu tempo.','https://vidaorganizada.com/','▦'),
 ('foco','Uma coisa de cada vez','Foco','Descubra o Pomodoro e encontre seu ritmo de concentração.','https://www.pomodorotechnique.com/','◷');
create table public.favoritos (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 conteudo_id text not null references public.biblioteca(id),
 unique(user_id,conteudo_id)
);
-- RLS: dados pessoais nunca ficam acessíveis com a chave pública sem sessão.
alter table public.tarefas enable row level security;
alter table public.habitos enable row level security;
alter table public.habitos_registros enable row level security;
alter table public.sessoes_foco enable row level security;
alter table public.biblioteca enable row level security;
alter table public.favoritos enable row level security;
create policy tarefas_pessoais on public.tarefas for all to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
create policy registros_pessoais on public.habitos_registros for all to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
create policy sessoes_pessoais on public.sessoes_foco for all to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
create policy favoritos_pessoais on public.favoritos for all to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
create policy leitura_habitos on public.habitos for select to authenticated using (true);
create policy leitura_biblioteca on public.biblioteca for select to authenticated using (true);
grant select,insert,update,delete on public.tarefas,public.habitos_registros,public.sessoes_foco,public.favoritos to authenticated;
grant select on public.habitos,public.biblioteca to authenticated;
create index tarefas_usuario on public.tarefas(user_id);
create index sessoes_usuario on public.sessoes_foco(user_id,finalizada_em);
-- Realtime para atualizações entre dispositivos; polling e foco da janela são fallback.
alter publication supabase_realtime add table public.tarefas,public.habitos_registros,public.sessoes_foco,public.favoritos;
commit;
