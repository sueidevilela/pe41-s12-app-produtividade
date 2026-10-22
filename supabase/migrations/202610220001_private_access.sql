-- Aplicar depois da migration inicial. Não altera donos nem apaga histórico.
begin;
do $$
declare t text;
begin
 foreach t in array array['tarefas','habitos_registros','sessoes_foco','favoritos'] loop
  execute format('alter table public.%I enable row level security',t);
  execute format('alter table public.%I force row level security',t);
  execute format('alter table public.%I alter column user_id set default auth.uid()',t);
  execute format('alter table public.%I alter column user_id set not null',t);
  execute format('revoke all on public.%I from anon, public',t);
  execute format('revoke truncate,references,trigger on public.%I from authenticated',t);
  execute format('grant select,insert,update,delete on public.%I to authenticated',t);
  -- Restritiva: mesmo uma política permissiva antiga não pode abrir dados alheios.
  execute format('drop policy if exists owner_required on public.%I',t);
  execute format('create policy owner_required on public.%I as restrictive for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id)',t);
  execute format('drop policy if exists owner_access on public.%I',t);
  execute format('create policy owner_access on public.%I for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id)',t);
 end loop;
 -- Catálogos fixos são compartilhados somente para leitura autenticada.
 foreach t in array array['habitos','biblioteca'] loop
  execute format('alter table public.%I enable row level security',t);
  execute format('revoke all on public.%I from anon, public',t);
  execute format('revoke insert,update,delete,truncate,references,trigger on public.%I from authenticated',t);
  execute format('grant select on public.%I to authenticated',t);
 end loop;
end $$;
commit;
