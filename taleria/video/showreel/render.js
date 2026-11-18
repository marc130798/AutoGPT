const {chromium}=require('playwright');const fs=require('fs');(async()=>{const [w,h,out]=process.argv.slice(2);const b=await chromium.launch();
const p=await b.newPage({viewport:{width:+w,height:+h}});await p.goto('file://'+process.cwd()+'/reel.html?w='+w+'&h='+h);await p.evaluate(()=>document.fonts.ready);await p.waitForTimeout(800);
fs.writeFileSync('sfx.json',JSON.stringify(await p.evaluate(()=>window.SFX)));fs.mkdirSync(out,{recursive:true});
for(let f=0;f<Math.round(await p.evaluate(()=>REEL.total)*30);f++){await p.evaluate(t=>render(t),f/30);await p.screenshot({path:`${out}/f${String(f).padStart(4,'0')}.jpg`,type:'jpeg',quality:90});}
await b.close();console.log('fertig',out)})()
