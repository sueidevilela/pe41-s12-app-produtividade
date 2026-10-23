import { createClient } from '@supabase/supabase-js';
const url=import.meta.env.VITE_SUPABASE_URL,key=import.meta.env.VITE_SUPABASE_ANON_KEY;
export const supabase=url&&key?createClient(url,key):null;
export const storageKey='florescer-demo-v1';
export function loadLocal(){try{return JSON.parse(localStorage.getItem(storageKey))||{}}catch{return {}}}
export async function fetchData(){
 const setupMissing=[];
 const tables=['tarefas','habitos','habitos_registros','sessoes_foco','biblioteca','favoritos','projetos','compromissos'];
 const results=await Promise.all(tables.map(async table=>{
  const rows=[];
  for(let offset=0;;offset+=500){
   const {data,error}=await supabase.from(table).select('*').order('id').range(offset,offset+499).abortSignal(AbortSignal.timeout(15000));
   if(error){if(['projetos','compromissos'].includes(table)&&['42P01','PGRST205'].includes(error.code)){setupMissing.push(table);return [table,[]];}throw error;}rows.push(...data);if(data.length<500)break;
  }
  return [table,rows];
 }));
 return {...Object.fromEntries(results),setupMissing};
}
export function explainError(error) {
 const code=error?.code;
 if(/abort|timeout/i.test(error?.message||''))return 'O Supabase demorou para responder. Atualize a página para conferir se o registro foi salvo antes de tentar novamente.';
 if(['42P01','42703','PGRST204','PGRST205'].includes(code))return 'A estrutura do Supabase ainda não acompanha esta versão do aplicativo. Execute o arquivo supabase/repair_setup.sql no SQL Editor do seu projeto e tente novamente. Seus dados existentes serão preservados.';
 if(code==='42501')return 'Sua conta não tem permissão para esta gravação. Confira as migrations de segurança no Supabase. Não desative as políticas de acesso.';
 if(code==='23503')return 'O projeto selecionado não está disponível para sua conta. Atualize a página e selecione um projeto seu.';
 if(code==='23514')return 'Confira os campos: o título precisa ter texto e os valores devem respeitar os limites do formulário.';
 if(error?.status===401||code==='PGRST301')return 'Sua sessão não é mais válida. Saia e entre novamente.';
 return error?.message||'Não foi possível salvar. Confira sua conexão e tente novamente.';
}
export async function saveRow(table,row){
 if('titulo' in row && !row.titulo?.trim())throw new Error('Escreva um título antes de salvar.');
 const payload={...row};
 // Compatibilidade apenas para campos novos opcionais sem conteúdo. Nunca descartar informação preenchida.
 for(let attempt=0;attempt<8;attempt++){
  const {data,error}=await supabase.from(table).upsert(payload).select().single().abortSignal(AbortSignal.timeout(15000));
  if(!error)return data;
  const missing=error.code==='PGRST204'?error.message.match(/Could not find the '([^']+)' column/)?.[1]:null;
  if(table==='tarefas'&&['projeto_id','esforco','proximo_passo','plano_se_entao','concluida_em'].includes(missing)&&Object.hasOwn(payload,missing)&&payload[missing]==null){delete payload[missing];continue;}
  throw error;
 }
 throw new Error('Não foi possível confirmar a gravação. Atualize a estrutura do Supabase.');
}
export async function removeRow(table,id){const {error}=await supabase.from(table).delete().eq('id',id).abortSignal(AbortSignal.timeout(15000));if(error)throw error;}

// Importação explícita: uma cópia local nunca é atribuída automaticamente à primeira conta.
export async function importLocalHistory(userId) {
 const {data:{user},error}=await supabase.auth.getUser();
 if(error||!user||user.id!==userId)throw new Error('Entre novamente antes de importar seu histórico.');
 const old=loadLocal();
 const fields={tarefas:['titulo','prioridade','prazo','concluida','esforco'],habitos_registros:['habito','data','concluido'],sessoes_foco:['duracao_minutos','segundos_realizados','concluida','finalizada_em'],favoritos:['conteudo_id']};
 const conflicts={tarefas:'id',habitos_registros:'user_id,habito,data',sessoes_foco:'id',favoritos:'user_id,conteudo_id'};
 const total=Object.keys(fields).reduce((n,t)=>n+(Array.isArray(old[t])?old[t].length:0),0);
 if(!total)return 0;
 const ownerKey=storageKey+'-owner';
 const owner=localStorage.getItem(ownerKey);
 if(owner&&owner!==userId)throw new Error('Este histórico local já está vinculado a outra conta.');
 // Gravar antes da importação impede que uma segunda conta importe uma cópia parcial.
 localStorage.setItem(ownerKey,userId);
 for(const [table,columns] of Object.entries(fields)){
  for(const row of old[table]||[]){
   if(typeof row.id!=='string')throw new Error('Formato de histórico inválido. Os dados originais foram preservados.');
   const record={id:row.id,user_id:userId};
   if(table==='tarefas')record.concluida_em=row.concluida_em||null;
   for(const column of columns)if(row[column]!==undefined)record[column]=row[column];
   const {error}=await supabase.from(table).upsert(record,{onConflict:conflicts[table],ignoreDuplicates:true});
   if(error)throw error;
  }
 }
 return total;
}
