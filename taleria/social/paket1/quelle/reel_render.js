// node reel_render.js <reel> <ordner>  → Einzelbilder + sfx.json
const {chromium}=require('playwright');const fs=require('fs');const path=require('path');
(async()=>{const [reel,out]=process.argv.slice(2);const b=await chromium.launch();const p=await b.newPage({viewport:{width:1080,height:1920}});
await p.goto('file://'+path.resolve('reels.html')+'?reel='+reel);await p.evaluate(()=>document.fonts.ready);await p.waitForTimeout(800);
fs.mkdirSync(out,{recursive:true});fs.writeFileSync(out+'/sfx.json',JSON.stringify(await p.evaluate(()=>window.SFX)));
const n=Math.round(await p.evaluate(()=>REEL.total)*30);
for(let f=0;f<n;f++){await p.evaluate(t=>render(t),f/30);await p.screenshot({path:`${out}/f${String(f).padStart(4,'0')}.jpg`,type:'jpeg',quality:88});}
await b.close();console.log(reel,n,'Bilder');})();
