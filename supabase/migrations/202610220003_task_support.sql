begin;
alter table public.tarefas add column if not exists proximo_passo text check (length(proximo_passo)<=500);
alter table public.tarefas add column if not exists plano_se_entao text check (length(plano_se_entao)<=500);
-- Anotações privadas: continuam protegidas pelas políticas user_id existentes.
commit;
