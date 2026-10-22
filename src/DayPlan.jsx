import React from 'react';
import StartSupport from './StartSupport';
import { habits } from './data';
import { orderedToday, explainPosition, daySummary, patternInsights } from './planning';
export default function DayPlan({ data, today, busy, write, loaded, onFocus }) {
  if (!loaded) return <section className="panel"><p>Carregando seus registros para organizar o dia…</p></section>;
  const tasks = orderedToday(data.tarefas, today), summary = daySummary(data, today);
  const insights = patternInsights({ ...data, habitos: data.habitos.length ? data.habitos : habits }, today);
  return <>
    <section className="panel daily-overview"><span className="eyebrow">SEU DIA EM PERSPECTIVA</span><h2>Progresso que cabe na vida.</h2>
      <div className="stats daily-stats">
        <div className="stat"><small>Tarefas concluídas / total do dia</small><strong>{summary.completed} / {summary.total}</strong></div>
        <div className="stat"><small>Hábitos cumpridos hoje</small><strong>{summary.habits} / {data.habitos.length || habits.length}</strong></div>
        <div className="stat"><small>Foco registrado hoje</small><strong>{Math.floor(summary.seconds/60)} min {Math.floor(summary.seconds%60)} s</strong></div>
      </div>
      <details className="summary-method"><summary>Como este resumo é calculado</summary><p className="muted">O dia inclui pendentes sem prazo, com prazo até hoje e tarefas concluídas hoje. O foco soma o tempo realizado nas sessões salvas na data de hoje, inclusive interrompidas; o cronômetro em andamento não entra ainda.</p>
      {data.tarefas.some(t => t.concluida && !t.concluida_em) && <p className="muted">Conclusões antigas sem data não entram no resumo diário: não sabemos em qual dia aconteceram.</p>}</details>
    </section>
    <section className="panel next-actions"><span className="eyebrow">CLAREZA PARA COMEÇAR</span><h2>Um passo. Depois, o próximo.</h2><StartSupport task={tasks[0]} write={write} busy={busy} onFocus={onFocus}/>
      <p className="muted">Primeiro o prazo mais próximo; em empate, maior importância; depois, menor esforço. Sem prazo e esforço não informado ficam ao final do respectivo critério. Tarefas futuras ficam na lista geral abaixo.</p>
      {tasks.length ? <ol className="day-plan">{tasks.map((task, index) => <li key={task.id}>
        {index === 0 && <span className="start-here">✧ Comece por esta, se fizer sentido para você</span>}
        <div className="day-plan-title"><input type="checkbox" aria-label={`Concluir agora ${task.titulo}`} disabled={busy} checked={false} onChange={() => write('tarefas', { ...task, concluida: true })} /><strong>{task.titulo}</strong></div>
        <details className="position-reason"><summary>Por que esta posição?</summary><p>{explainPosition(task, tasks[index-1], today)}</p></details>{task.proximo_passo&&<p className="saved-step">↳ Primeiro passo: {task.proximo_passo}</p>}{task.plano_se_entao&&<p className="saved-step">{task.plano_se_entao}</p>}
      </li>)}</ol> : <p>Não há tarefas pendentes para hoje. Você pode aproveitar uma pausa ou escolher o próximo passo na lista geral.</p>}
    </section>
    <section className="panel"><h2>O que seu histórico mostra</h2>{insights.map(message => <p className="pattern-note" key={message}>{message}</p>)}<small className="muted">Janela de observação: últimos 7 dias, no fuso do seu dispositivo. Sem previsões ou cobranças.</small></section>
  </>;
}
