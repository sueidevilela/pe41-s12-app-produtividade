import React, { useEffect, useState } from 'react';
import { supabase } from './store';
import AuthScreen from './AuthScreen';

export default function SecureApp({ children }) {
  const [session, setSession] = useState(null);
  const [ready, setReady] = useState(false);
  const [error, setError] = useState('');
  const [recovery, setRecovery] = useState(() => new URLSearchParams(location.search).get('reset') === '1' || new URLSearchParams(location.hash.slice(1)).get('type') === 'recovery');
  useEffect(() => {
    if (!supabase) return;
    let alive = true;
    let observedEvent = false;
    const { data: listener } = supabase.auth.onAuthStateChange((event, next) => {
      observedEvent = true;
      if (!alive) return;
      if (event === 'PASSWORD_RECOVERY') setRecovery(true);
      setSession(next);
      setReady(true);
    });
    supabase.auth.getSession().then(({ data, error }) => {
      if (!alive || observedEvent) return;
      if (error) setError(error.message);
      setSession(error ? null : data.session);
      setReady(true);
    }).catch(() => {
      if (alive && !observedEvent) { setError('Não foi possível verificar a sessão. Atualize a página.'); setReady(true); }
    });
    return () => { alive = false; listener.subscription.unsubscribe(); };
  }, []);
  if (!supabase) return <div className="login"><section className="login-card"><div className="brand-symbol">✿</div><h1>Seu espaço</h1><h2>Acesso bloqueado</h2><p>Configure a conexão com o Supabase para entrar. Nenhum dado local foi apagado.</p></section></div>;
  if (!ready) return <div className="login"><p>Verificando seu acesso…</p></div>;
  if (!session || recovery) return <AuthScreen key={recovery ? 'reset' : 'login'} session={session} recovery={recovery} initialError={error} onRecovered={() => {
    const url = new URL(location.href); url.searchParams.delete('reset'); url.hash = '';
    window.history.replaceState(null, '', url.pathname + url.search);
    setRecovery(false); setError('');
  }} />;
  // Uma troca de conta desmonta todo o estado privado, inclusive o cronômetro.
  return children(session);
}
