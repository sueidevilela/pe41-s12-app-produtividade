import { createClient } from '@supabase/supabase-js';
const url=import.meta.env.VITE_SUPABASE_URL,key=import.meta.env.VITE_SUPABASE_ANON_KEY;
export const supabase=url&&key?createClient(url,key):null;
export const storageKey='florescer-demo-v1';
export function loadLocal(){try{return JSON.parse(localStorage.getItem(storageKey))||{}}catch{return {}}}
export async function fetchData(){
 const tables=['tarefas','habitos','habitos_registros','sessoes_foco','biblioteca','favoritos'];
 const results=await Promise.all(tables.map(t=>supabase.from(t).select('*')));
 const error=results.find(r=>r.error)?.error;if(error)throw error;
 return Object.fromEntries(tables.map((t,i)=>[t,results[i].data]));
}
export async function saveRow(table,row){const {error}=await supabase.from(table).upsert(row);if(error)throw error;}
export async function removeRow(table,id){const {error}=await supabase.from(table).delete().eq('id',id);if(error)throw error;}
