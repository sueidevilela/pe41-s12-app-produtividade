begin;
alter table public.compromissos add column if not exists projeto_id uuid;
do $$ begin
 if not exists(select 1 from pg_constraint where conrelid='public.compromissos'::regclass and conname='compromissos_projeto_dono') then
  alter table public.compromissos add constraint compromissos_projeto_dono foreign key(projeto_id,user_id) references public.projetos(id,user_id);
 end if;
end $$;
create index if not exists compromissos_projeto on public.compromissos(projeto_id);
notify pgrst, 'reload schema';
commit;
