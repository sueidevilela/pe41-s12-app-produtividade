import {localDate} from './data';
const dayNumber = date => {const [y,m,d]=date.split('-').map(Number);return Date.UTC(y,m-1,d)/86400000};
function shift(date,days){const d=new Date(dayNumber(date)*86400000);d.setUTCDate(d.getUTCDate()+days);return d.toISOString().slice(0,10)}
export function isWeeklyDate(task,date){return !!task.recorrente_semanal&&!!task.prazo&&date>=task.prazo&&(dayNumber(date)-dayNumber(task.prazo))%7===0}
export function nextWeeklyDate(task,today=localDate()){if(!task.prazo)return null;return shift(task.prazo,Math.max(0,Math.ceil((dayNumber(today)-dayNumber(task.prazo))/7))*7)}
export function calendarTask(task,date,records=[]){
 const record=records.find(r=>r.tarefa_id===task.id&&r.data===date);
 if(isWeeklyDate(task,date))return {...task,prazo:date,ocorrencia_data:date,concluida:!!record?.concluida,concluida_em:record?.concluida_em||null};
 // Ocorrências já registradas continuam visíveis mesmo ao desativar ou alterar a série.
 if(record?.concluida)return {...task,prazo:date,ocorrencia_data:date,concluida:true,concluida_em:record.concluida_em};
 return !task.recorrente_semanal&&task.prazo===date?task:null;
}
export function calendarTasks(tasks,date,records=[]){return tasks.map(t=>calendarTask(t,date,records)).filter(Boolean)}
export function listTask(task,records=[],today=localDate()){
 if(!task.recorrente_semanal)return task;
 const date=nextWeeklyDate(task,today);
 return date?calendarTask(task,date,records):task;
}
export function dailyTasks(tasks,records,today){
 const result=tasks.filter(t=>!t.recorrente_semanal);
 for(const t of tasks.filter(t=>t.recorrente_semanal)){
  const instance=calendarTask(t,today,records);if(instance)result.push({...instance,id:`${t.id}:${today}`,serie_id:t.id});
 }
 // Conclusões de uma série em outra data de agenda contam no dia em que foram registradas.
 for(const r of records.filter(r=>r.concluida&&r.concluida_em&&localDate(new Date(r.concluida_em))===today)){
  const t=tasks.find(t=>t.id===r.tarefa_id);if(!t)continue;
  const id=`${t.id}:${r.data}`;
  if(!result.some(x=>x.id===id))result.push({...t,id,serie_id:t.id,prazo:r.data,ocorrencia_data:r.data,concluida:true,concluida_em:r.concluida_em});
 }
 return result;
}
