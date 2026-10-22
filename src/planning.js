import { localDate } from './data';
const importance = { alta: 0, media: 1, baixa: 2 };
const effort = { baixo: 0, medio: 1, alto: 2 };
export const importanceLabel = { alta: 'alta', media: 'média', baixa: 'baixa' };
export const effortLabel = { baixo: 'baixo', medio: 'médio', alto: 'alto' };
export function isTodayTask(task, today) {
  return task.concluida
    ? !!task.concluida_em && localDate(new Date(task.concluida_em)) === today
    : !task.prazo || task.prazo <= today;
}
const deadline = task => task.prazo || '9999-12-31';
export function compareTasks(a, b) {
  return deadline(a).localeCompare(deadline(b)) ||
    (importance[a.prioridade] ?? 3) - (importance[b.prioridade] ?? 3) ||
    (effort[a.esforco] ?? 3) - (effort[b.esforco] ?? 3) || a.id.localeCompare(b.id);
}
export function orderedToday(tasks, today) {
  return tasks.filter(t => !t.concluida && isTodayTask(t, today)).sort(compareTasks);
}
export function explainPosition(task, previous, today) {
  const due = !task.prazo ? 'sem prazo definido' : task.prazo < today ? `prazo em ${task.prazo.split('-').reverse().join('/')}, anterior a hoje` : 'prazo hoje';
  const details = `${due}; importância ${importanceLabel[task.prioridade] || 'não informada'}; esforço ${effortLabel[task.esforco] || 'não informado'}.`;
  if (!previous) return `Primeira na ordem de prazo → importância → esforço: ${details}`;
  const reason = deadline(task) !== deadline(previous) ? 'O prazo vem depois do item anterior.' :
    task.prioridade !== previous.prioridade ? 'Com o mesmo prazo, a importância define esta posição.' :
    task.esforco !== previous.esforco ? 'Com prazo e importância iguais, vem primeiro o menor esforço informado; o não informado fica por último.' :
    'Empate nos três critérios: mantemos uma ordem estável pelo identificador, sem atribuir importância extra.';
  return `${reason} ${details}`;
}
export function daySummary(data, today) {
  const tasks = data.tarefas.filter(t => isTodayTask(t, today));
  const sessions = data.sessoes_foco.filter(s => localDate(new Date(s.finalizada_em)) === today);
  return { total: tasks.length, completed: tasks.filter(t => t.concluida).length,
    habits: new Set(data.habitos_registros.filter(r => r.data === today && r.concluido).map(r => r.habito)).size,
    seconds: sessions.reduce((sum, s) => sum + Math.max(0, Number(s.segundos_realizados) || 0), 0) };
}
export function patternInsights(data, today) {
  const messages = [];
  const start = new Date(`${today}T12:00:00`); start.setDate(start.getDate() - 6);
  const since = localDate(start);
  const records = data.habitos_registros.filter(r => r.data >= since && r.data <= today);
  const days = new Set(records.map(r => r.data)).size;
  if (days >= 3) {
    const counts = {};
    for (const r of records.filter(r => r.concluido)) (counts[r.habito] ||= new Set()).add(r.data);
    const ranked = Object.entries(counts).sort((a,b) => b[1].size-a[1].size || a[0].localeCompare(b[0]));
    if (ranked.length) {
      const best = ranked[0][1].size, winners = ranked.filter(([, dates]) => dates.size === best);
      const names = winners.map(([id]) => data.habitos.find(h => h.id === id)?.titulo || id).join(', ');
      messages.push(`Nos últimos 7 dias, ${names} ${winners.length > 1 ? 'tiveram mais dias marcados' : 'teve mais dias marcados'}: ${best}. Há registros em ${days} dias; ausência de registro não significa que você não realizou o hábito.`);
    }
  }
  const sessions = data.sessoes_foco.filter(s => { const d = localDate(new Date(s.finalizada_em)); return d >= since && d <= today; });
  if (sessions.length >= 3) {
    const seconds = sessions.reduce((n,s) => n + Math.max(0, Number(s.segundos_realizados)||0),0);
    messages.push(`Nas ${sessions.length} sessões registradas nos últimos 7 dias, seu tempo médio realizado foi de ${Math.floor(seconds/sessions.length/60)} min. Inclui sessões interrompidas salvas; é uma observação, não uma meta.`);
  }
  return messages.length ? messages : ['Ainda não há registros suficientes para observar padrões. Conforme você usa o aplicativo, este espaço mostra apenas o que seu histórico permite perceber.'];
}
