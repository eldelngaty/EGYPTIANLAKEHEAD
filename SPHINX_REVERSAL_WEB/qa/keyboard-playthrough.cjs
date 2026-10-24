// Full end-to-end playthrough using only actual browser keyboard/button inputs.
// The development adapter is used to OBSERVE position/state, never to move or mutate.
const {chromium,launchOptions}=require('./browser.cjs');
const fs=require('node:fs');const assert=require('node:assert/strict');
(async()=>{
 const browser=await chromium.launch(launchOptions);
 const page=await browser.newPage({viewport:{width:1280,height:800}}),errors=[],milestones=[];
 page.on('pageerror',e=>{errors.push(e.message);console.log('ERROR',e.message)});page.on('console',m=>{if(m.type()==='error'){errors.push(m.text());console.log('CONSOLE ERROR',m.text());}});
 await page.goto('http://127.0.0.1:5173/?qa');await page.click('#start');
 const state=()=>page.evaluate(()=>window.__sphinxQA.snapshot());let held=new Set();
 async function release(){for(const key of held)await page.keyboard.up(key);held.clear();}
 async function walk(x,z){const start=Date.now();let lastDist=Infinity;
  while(Date.now()-start<45000){const p=await state(),dx=x-p.x,dz=z-p.z,d=Math.hypot(dx,dz);if(d<.22){await release();await page.waitForTimeout(80);console.log('AT',x,z);return;}
   const right=dx*.838444-dz*.544988,forward=-dx*.544988-dz*.838444;
   const next=new Set();const max=Math.max(Math.abs(right),Math.abs(forward));if(Math.abs(right)>max*.4)next.add(right>0?'d':'a');if(Math.abs(forward)>max*.4)next.add(forward>0?'w':'s');
   for(const key of held)if(!next.has(key))await page.keyboard.up(key);
   for(const key of next)if(!held.has(key))await page.keyboard.down(key);held=next;
   await page.waitForTimeout(d<.8?45:100);lastDist=d;
  }await release();throw Error(`Movement timeout ${x},${z}; state ${JSON.stringify(await state())}`);
 }
 async function pressR(){await release();const old=(await state()).ancient;await page.waitForTimeout(950);await page.keyboard.press('r');await page.waitForFunction(old=>window.__sphinxQA.snapshot().ancient!==old,old,{timeout:5000});}
 async function E(){await release();await page.keyboard.press('e');await page.waitForTimeout(150);}
 async function milestone(name,condition){assert(condition,name);milestones.push(name);console.log('PASS',name);}
 await walk(-6,4);await walk(-6,-7);await pressR();await page.screenshot({path:'qa/keyboard-first-reversal.png'});await walk(-16.8,-7);await E();await milestone('A reached with real WASD', (await state()).coins.includes('A'));
 await walk(-6,-7);await walk(7,-7);await walk(13.3,-7);await pressR();await walk(18.3,-7);await E();await milestone('Bridge/gate puzzle and B with real WASD/R/E',(await state()).coins.includes('B'));
 await walk(13.3,-7);await pressR();await walk(7,-7);await walk(0,-13.5);await E();await milestone('Hidden seal C with real WASD/R/E',(await state()).coins.includes('C'));
 await walk(0,10.6);await E();await page.keyboard.press('c');await page.keyboard.press('b');await page.keyboard.press('a');await page.waitForTimeout(150);await milestone('Reverse-order shrine using C/B/A keys',(await state()).shrineActive);
 await E();await milestone('Map revealed through E in ancient reality',(await state()).mapFound);await page.keyboard.press('m');
 await walk(0,-17);await walk(0,-22);await walk(2,-22);await pressR();await E();await milestone('Present-day prison anchor severed',(await state()).anchorReleased);
 await walk(0,-23);await pressR();await E();await milestone('Final reversal rescues Nefertiti',(await state()).finished);
 await page.waitForSelector('#victory:not(.hidden)',{timeout:20000});const final=await state();await page.screenshot({path:'qa/keyboard-victory.png'});await milestone('Cinematic finishes',await page.locator('#victory').isVisible());await page.click('#restart');const reset=await state();await milestone('Normal restart clears all progress',reset.coins.length===0&&!reset.finished&&!reset.anchorReleased&&!reset.mapFound);
 await milestone('Zero critical browser errors',errors.length===0);
 const report={method:'Complete normal keyboard playthrough: actual WASD, R, E, C/B/A, M and restart button. Adapter used only for observing state; no physics replay, teleports or state changes.',date:new Date().toISOString(),browser:'Chromium 131 headless / SwiftShader',milestones,errors,final};fs.writeFileSync('qa/keyboard-verified.json',JSON.stringify(report,null,2));console.log(JSON.stringify(report,null,2));await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
