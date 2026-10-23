import {localDate} from './data';
export const recurrenceLabels={semanal:'Semanal',mensal:'Mensal',anual:'Anual'};
export function recurrenceKind(task){return task.recorrencia||(task.recorrente_semanal?'semanal':null)}
const dayNumber=date=>Date.parse(`${date}T00:00:00Z`)/86400000;
function shift(date,days){return new Date((dayNumber(date)+days)*86400000).toISOString().slice(0,10)}
function inMonth(year,month,day){const end=new Date(0);end.setUTCHours(0,0,0,0);end.setUTCFullYear(year,month,0);return `${String(year).padStart(4,'0')}-${String(month).padStart(2,'0')}-${String(Math.min(day,end.getUTCDate())).padStart(2,'0')}`}
export function isOccurrenceDate(task,date){
 const kind=recurrenceKind(task);if(!kind||!task.prazo||date<task.prazo)return false;
 if(kind==='semanal')return (dayNumber(date)-dayNumber(task.prazo))%7===0;
 const [year,month]=date.split('-').map(Number),[,anchorMonth,anchorDay]=task.prazo.split('-').map(Number);
 if(kind==='mensal')return date===inMonth(year,month,anchorDay);
 if(kind==='anual')return month===anchorMonth&&date===inMonth(year,anchorMonth,anchorDay);
 return false;
}
export function isWeeklyDate(task,date){return recurrenceKind(task)==='semanal'&&isOccurrenceDate(task,date)}
export function nextOccurrence(task,today=localDate()){
 const kind=recurrenceKind(task);if(!kind||!task.prazo)return null;if(today<=task.prazo)return task.prazo;
 if(kind==='semanal')return shift(task.prazo,Math.max(0,Math.ceil((dayNumber(today)-dayNumber(task.prazo))/7))*7);
 const [year,month]=today.split('-').map(Number),[,anchorMonth,anchorDay]=task.prazo.split('-').map(Number);
 if(kind==='mensal'){const date=inMonth(year,month,anchorDay);if(date>=today)return date;const index=year*12+month;return inMonth(Math.floor(index/12),index%12+1,anchorDay)}
 if(kind==='anual'){const date=inMonth(year,anchorMonth,anchorDay);return date>=today?date:inMonth(year+1,anchorMonth,anchorDay)}
 return null;
}
export function nextWeeklyDate(task,today=localDate()){return nextOccurrence(task,today)}
export function calendarTask(task,date,records=[]){
 const record=records.find(r=>r.tarefa_id===task.id&&r.data===date);
 if(isOccurrenceDate(task,date))return {...task,prazo:date,ocorrencia_data:date,concluida:!!record?.concluida,concluida_em:record?.concluida_em||null};
 if(record?.concluida)return {...task,prazo:date,ocorrencia_data:date,concluida:true,concluida_em:record.concluida_em};
 return !recurrenceKind(task)&&task.prazo===date?task:null;
}
export function calendarTasks(tasks,date,records=[]){return tasks.map(t=>calendarTask(t,date,records)).filter(Boolean)}
export function listTask(task,records=[],today=localDate()){
 if(!recurrenceKind(task))return task;
 const date=nextOccurrence(task,today);return date?calendarTask(task,date,records):task;
}
export function dailyTasks(tasks,records,today){
 const result=tasks.filter(t=>!recurrenceKind(t));
 for(const t of tasks.filter(t=>recurrenceKind(t))){
  const instance=calendarTask(t,today,records);if(instance)result.push({...instance,id:`${t.id}:${today}`,serie_id:t.id});
 }
 for(const r of records.filter(r=>r.concluida&&r.concluida_em&&localDate(new Date(r.concluida_em))===today)){
  const t=tasks.find(t=>t.id===r.tarefa_id);if(!t)continue;
  const id=`${t.id}:${r.data}`;
  if(!result.some(x=>x.id===id))result.push({...t,id,serie_id:t.id,prazo:r.data,ocorrencia_data:r.data,concluida:true,concluida_em:r.concluida_em});
 }
 return result;
}
