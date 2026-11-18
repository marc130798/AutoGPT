// Fotografiert jede Folie aus folien.html als JPG (1080 breit). Aufruf: node fotografieren.js
const {chromium}=require('playwright');const fs=require('fs');const path=require('path');
(async()=>{const b=await chromium.launch();const p=await b.newPage({viewport:{width:1080,height:1920}});
await p.goto('file://'+path.resolve('folien.html'));await p.evaluate(()=>document.fonts.ready);await p.waitForTimeout(600);
const out=path.resolve('../bilder');fs.mkdirSync(out,{recursive:true});
const ids=await p.$$eval('section',s=>s.map(x=>x.id));
for(const id of ids){const el=await p.$('#'+id);await el.screenshot({path:`${out}/${id}.jpg`,type:'jpeg',quality:90});}
const broken=await p.$$eval('img',i=>i.filter(x=>!x.naturalWidth).map(x=>x.getAttribute('src')));
console.log(ids.length,'Folien; fehlende Bilder:',broken);await b.close();})();
