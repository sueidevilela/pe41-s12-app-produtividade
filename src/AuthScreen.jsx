import React, { useState } from 'react';
import { supabase } from './store';

export default function AuthScreen({ recovery, session, initialError, onRecovered }) {
  const [mode, setMode] = useState(recovery ? 'reset' : 'login');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmation, setConfirmation] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(initialError || '');
  const [notice, setNotice] = useState('');
  const reset = recovery || mode === 'reset';
  const forgot = !reset && mode === 'forgot';

  function switchMode(next) {
    setMode(next);
    setPassword('');
    setConfirmation('');
    setError('');
    setNotice('');
  }

  async function submit(event) {
    event.preventDefault();
    setError('');
    setNotice('');
    if (reset && password !== confirmation) {
      setError('As senhas precisam ser iguais.');
      return;
    }
    setBusy(true);
    try {
      if (reset) {
        if (!session) throw new Error('Este link expirou ou já foi utilizado. Solicite um novo e-mail de recuperação.');
        const { error } = await supabase.auth.updateUser({ password });
        if (error) throw error;
        setPassword('');
        setConfirmation('');
        setNotice('Senha atualizada com sucesso.');
        onRecovered();
      } else if (forgot) {
        const redirectTo = new URL(window.location.pathname, window.location.origin);
        redirectTo.searchParams.set('reset', '1');
        const { error } = await supabase.auth.resetPasswordForEmail(email.trim(), { redirectTo: redirectTo.href });
        if (error) throw error;
        setNotice('Se houver uma conta com esse e-mail, você receberá um link. Confira também o spam. Para reenviar, aguarde pelo menos um minuto.');
      } else {
        const { error } = await supabase.auth.signInWithPassword({ email: email.trim(), password });
        if (error) throw error;
        setPassword('');
      }
    } catch (err) {
      if (err.status === 429) setError('Aguarde pelo menos um minuto antes de solicitar outro e-mail.');
      else if (err.code === 'invalid_credentials') setError('E-mail ou senha incorretos.');
      else setError(err.message || 'Não foi possível concluir. Tente novamente.');
    } finally {
      setBusy(false);
    }
  }

  return <div className="login"><form className="login-card" onSubmit={submit}>
    <div className="brand-symbol">✿</div><h1>Florescer</h1>
    <p>Um espaço para cuidar do seu tempo.</p>
    <h2>{reset ? 'Defina sua nova senha' : forgot ? 'Recuperar acesso' : 'Bem-vinda de volta'}</h2>
    {reset && !session ? <p role="alert">Este link não é válido ou expirou. Solicite um novo e-mail pelo aplicativo.</p> : <>
      {!reset && <label>E-mail<input type="email" required autoComplete="username" value={email} onChange={e => setEmail(e.target.value)} /></label>}
      {!forgot && <label>{reset ? 'Nova senha' : 'Senha'}<input type="password" required minLength={reset ? 8 : undefined} autoComplete={reset ? 'new-password' : 'current-password'} value={password} onChange={e => setPassword(e.target.value)} /></label>}
      {reset && <><small>Use pelo menos 8 caracteres.</small><label>Confirmar nova senha<input type="password" required minLength={8} autoComplete="new-password" value={confirmation} onChange={e => setConfirmation(e.target.value)} /></label></>}
      <button disabled={busy}>{busy ? 'Aguarde…' : reset ? 'Salvar nova senha' : forgot ? 'Enviar link de recuperação' : 'Entrar no meu espaço →'}</button>
    </>}
    {error && <p role="alert" className="error">{error}</p>}
    {notice && <p role="status">{notice}</p>}
    {!reset && <button type="button" className="ghost" disabled={busy} onClick={() => switchMode(forgot ? 'login' : 'forgot')}>{forgot ? 'Voltar para o login' : 'Esqueci minha senha'}</button>}
    {reset && !session && <button type="button" className="ghost" onClick={onRecovered}>Voltar para o login</button>}
    <small>Acesso pessoal. Sua conta é criada previamente no Supabase.</small>
  </form></div>;
}
