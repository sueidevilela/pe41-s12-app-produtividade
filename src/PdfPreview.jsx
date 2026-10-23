import React,{useEffect,useRef,useState} from 'react';
import {getDocument,GlobalWorkerOptions} from 'pdfjs-dist';
import workerUrl from 'pdfjs-dist/build/pdf.worker.min.mjs?url';
GlobalWorkerOptions.workerSrc=workerUrl;
export default function PdfPreview({blob,name}){
 const [doc,setDoc]=useState(null),[page,setPage]=useState(1),[error,setError]=useState(''),[width,setWidth]=useState(600),[rendering,setRendering]=useState(false);
 const canvas=useRef(null),container=useRef(null);
 useEffect(()=>{const element=container.current;const observer=new ResizeObserver(entries=>setWidth(Math.max(120,Math.floor(entries[0].contentRect.width))));observer.observe(element);return()=>observer.disconnect()},[]);
 useEffect(()=>{let alive=true,loading;setDoc(null);setPage(1);setError('');
  (async()=>{try{const data=new Uint8Array(await blob.arrayBuffer());if(!alive)return;
   loading=getDocument({data,isEvalSupported:false,enableXfa:false,useSystemFonts:true});
   loading.onPassword=()=>{if(alive)setError('Este PDF exige senha. Baixe uma cópia para abri-lo no seu leitor.');loading.destroy().catch(()=>{})};
   const pdf=await loading.promise;if(alive)setDoc(pdf);
  }catch(e){if(alive)setError(previous=>previous||'Não foi possível exibir este PDF. Você pode baixar uma cópia abaixo.');}})();
  return()=>{alive=false;loading?.destroy().catch(()=>{})};
 },[blob]);
 useEffect(()=>{if(!doc)return;let alive=true,render;
  setRendering(true);
  (async()=>{try{const pdfPage=await doc.getPage(page);if(!alive)return;const base=pdfPage.getViewport({scale:1}),viewport=pdfPage.getViewport({scale:Math.min(width/base.width,2)}),ratio=Math.min(window.devicePixelRatio||1,2),element=canvas.current;
   element.width=Math.ceil(viewport.width*ratio);element.height=Math.ceil(viewport.height*ratio);element.style.width=`${viewport.width}px`;element.style.height=`${viewport.height}px`;
   render=pdfPage.render({canvasContext:element.getContext('2d'),viewport,transform:ratio===1?null:[ratio,0,0,ratio,0,0]});await render.promise;
  }catch(e){if(alive&&e.name!=='RenderingCancelledException')setError('Não foi possível renderizar esta página. Você pode baixar uma cópia abaixo.');}finally{if(alive)setRendering(false)}})();
  return()=>{alive=false;render?.cancel()};
 },[doc,page,width]);
 return <div className="pdf-preview" ref={container}>{error?<p role="alert" className="error">{error}</p>:!doc?<p role="status">Carregando PDF…</p>:<><div className="pdf-controls"><button type="button" className="ghost" aria-label="Página anterior do PDF" disabled={page<=1} onClick={()=>setPage(p=>p-1)}>←</button><span aria-live="polite">Página {page} de {doc.numPages}</span><button type="button" className="ghost" aria-label="Próxima página do PDF" disabled={page>=doc.numPages} onClick={()=>setPage(p=>p+1)}>→</button></div>{rendering&&<p role="status">Exibindo página…</p>}</>}<canvas ref={canvas} role="img" aria-label={`${name}, página ${page}`} hidden={!doc||!!error}/><p className="muted">Prévia visual do documento. Para busca, seleção de texto ou leitura assistiva, baixe uma cópia.</p></div>;
}
