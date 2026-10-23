import React,{lazy,Suspense,useEffect,useRef,useState} from 'react';
import {supabase,explainError} from './store';
const PdfPreview=lazy(()=>import('./PdfPreview'));
export function previewType(bytes,name){
 if(bytes[0]===0x89&&bytes[1]===0x50&&bytes[2]===0x4e&&bytes[3]===0x47&&bytes[4]===0x0d&&bytes[5]===0x0a&&bytes[6]===0x1a&&bytes[7]===0x0a)return {kind:'image',mime:'image/png'};
 if(bytes[0]===0xff&&bytes[1]===0xd8&&bytes[2]===0xff)return {kind:'image',mime:'image/jpeg'};
 const header=new TextDecoder().decode(bytes);
 if(header.startsWith('GIF87a')||header.startsWith('GIF89a'))return {kind:'image',mime:'image/gif'};
 if(header.startsWith('RIFF')&&header.slice(8,12)==='WEBP')return {kind:'image',mime:'image/webp'};
 if(header.slice(0,1024).includes('%PDF-'))return {kind:'pdf'};
 if(/\.(txt|md|csv|json|log|ya?ml)$/i.test(name))return {kind:'text'};
 return {kind:'unsupported'};
}
export default function AttachmentPreview({file,prefix,onClose,onDownload,disabled}){
 const [preview,setPreview]=useState(null),[error,setError]=useState('');
 const name=file.name.slice(37),element=useRef(null);
 useEffect(()=>{if(preview)element.current?.scrollIntoView({block:'start',behavior:'smooth'})},[preview?.kind]);
 useEffect(()=>{let alive=true,url;setPreview(null);setError('');
  (async()=>{try{const {data,error}=await supabase.storage.from('anexos-tarefas').download(`${prefix}/${file.name}`);if(error)throw error;if(!alive)return;
   const bytes=new Uint8Array(await data.slice(0,1024).arrayBuffer());if(!alive)return;
   const type=previewType(bytes,name);
   if(type.kind==='image'){url=URL.createObjectURL(new Blob([data],{type:type.mime}));if(alive)setPreview({...type,url});}
   else if(type.kind==='pdf'){setPreview({...type,blob:data});}
   else if(type.kind==='text'){const text=await data.slice(0,1024*1024).text();if(alive)setPreview({...type,text,truncated:data.size>1024*1024});}
   else setPreview(type);
  }catch(e){if(alive)setError(explainError(e));}})();
  return()=>{alive=false;if(url)URL.revokeObjectURL(url)};
 },[file.name,prefix,name]);
 return <section ref={element} className="attachment-preview" aria-label={`Visualização de ${name}`}><div className="attachment-preview-heading"><strong>{name}</strong><button type="button" className="ghost" aria-label="Fechar visualização do anexo" onClick={onClose}>×</button></div>{error?<p role="alert" className="error">{error}</p>:!preview?<p role="status">Abrindo anexo…</p>:preview.kind==='image'?<img className="attachment-image" src={preview.url} alt={name} onError={()=>setError('Não foi possível exibir esta imagem. Você pode baixar o arquivo abaixo.')}/>:preview.kind==='pdf'?<Suspense fallback={<p role="status">Preparando leitor de PDF…</p>}><PdfPreview blob={preview.blob} name={name}/></Suspense>:preview.kind==='text'?<><pre className="attachment-text">{preview.text}</pre>{preview.truncated&&<p className="muted">Prévia limitada ao primeiro 1 MB. Baixe o arquivo para ler o conteúdo completo.</p>}</>:<p>Este formato não tem prévia no aplicativo. Você pode baixar o arquivo para abrir no programa adequado.</p>}<button type="button" className="ghost" disabled={disabled} onClick={()=>onDownload(file)}>↓ Baixar uma cópia</button></section>;
}
