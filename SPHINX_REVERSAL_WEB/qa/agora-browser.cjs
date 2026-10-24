// Real browser acceptance test, to be run where a local Chromium browser is allowed.
const {chromium,launchOptions,baseURL}=require('./browser.cjs');
const assert=require('node:assert/strict');
(async()=>{
 const browser=await chromium.launch(launchOptions);
 const page=await browser.newPage({viewport:{width:1440,height:900}});
 const errors=[];page.on('pageerror',e=>errors.push(e.message));
 page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
 await page.goto(baseURL+'?qa',{waitUntil:'networkidle'});
 await page.click('#start');await page.waitForTimeout(750);
 const state=()=>page.evaluate(()=>window.__sphinxQA.snapshot());
 const beginning=await state();assert(beginning.z>0&&!beginning.insideAgora,'Must spawn outside');
 // Genuine movement events, not direct coordinate mutation/teleportation.
 await page.keyboard.down('w');await page.waitForTimeout(2900);
 const entrance=await state();assert(entrance.doorOpen,'Automatic entrance doors did not open during approach');
 await page.waitForTimeout(1500);await page.keyboard.up('w');
 const inside=await state();assert(inside.insideAgora,`W failed to enter Agora: ${JSON.stringify(inside)}`);
 await page.screenshot({path:'qa/agora-browser-inside.png'});
 // Mouse drag rotates camera, and WASD direction changes correspondingly.
 await page.mouse.move(700,480);await page.mouse.down();await page.mouse.move(840,490,{steps:8});await page.mouse.up();
 const yaw=await state();assert(Math.abs(yaw.cameraYaw)>.1,'Mouse camera rotation failed');
 await page.keyboard.down('w');await page.waitForTimeout(330);await page.keyboard.up('w');
 const turned=await state();assert(turned.x>inside.x+.1,'Camera-relative movement after mouse look failed');
 // Reset camera direction via the test hook (camera only), then exit with real S.
 await page.evaluate(()=>window.__sphinxQA.rotateCamera(-140,-10));
 await page.keyboard.down('s');await page.waitForTimeout(4700);await page.keyboard.up('s');
 const outside=await state();assert(!outside.insideAgora,`Backtrack through door failed: ${JSON.stringify(outside)}`);
 await page.screenshot({path:'qa/agora-browser-return.png'});
 // Check side wall and original reversal gate conditions without mutating progression.
 const walls=await page.evaluate(()=>({side:window.__sphinxQA.world.blocked(9,-14),door:window.__sphinxQA.world.blocked(0,-9.55)}));
 assert(walls.side&&!walls.door,'Collision boundaries incorrect');
 assert(errors.length===0,`Runtime errors: ${errors.join(' | ')}`);
 console.log('PASS REAL BROWSER: outside -> WASD through entrance -> interior -> mouse look -> WASD -> outside -> collisions, no errors');
 await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
