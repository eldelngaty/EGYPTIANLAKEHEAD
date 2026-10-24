import * as THREE from '../vendor/three.module.min.js';
import {createWorld,makeSphinx} from './world.js';
import {dressCampus} from './dressing.js';
import {createAudio} from './audio.js';
import {batchStaticMeshes} from './optimize.js';
import {reality,createSky,createShockwave} from './reality.js';
import {campusReflectionFaces} from './campus_reflections.js';
import {setCampusEnvironment} from './agora.js';
import {loadTourReference} from './tour_reference.js';
import {FollowCamera,cameraVolumes,clipCamera} from './camera_rig.js';
// CSS is loaded by index.html to support offline ESM without Vite.

const $=id=>document.getElementById(id),app=$('app'),sound=createAudio();
let campusReflectionReady=false,referenceMode=false,tourCube=null,referenceYaw=0,referencePitch=0;
const scene=new THREE.Scene();scene.background=new THREE.Color('#88b7dc');scene.fog=new THREE.Fog('#88b7dc',30,110);
let renderer;
try{renderer=new THREE.WebGLRenderer({antialias:true,powerPreference:'high-performance'});}catch(e){$('fatal').classList.remove('hidden');throw e;}
renderer.setPixelRatio(Math.min(devicePixelRatio,1.5));renderer.shadowMap.enabled=true;renderer.shadowMap.type=THREE.PCFSoftShadowMap;
renderer.outputColorSpace=THREE.SRGBColorSpace;renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=1.0;app.prepend(renderer.domElement);
renderer.domElement.addEventListener('webglcontextlost',e=>{e.preventDefault();$('fatal-text').textContent='The graphics connection was interrupted. Reload to start a fresh adventure, or close other graphics-heavy tabs.';$('fatal').classList.remove('hidden');});
// Real tour imagery supplies reflections, never the playable geometry.
loadTourReference(campusReflectionFaces).then(tour=>{
 const pmrem=new THREE.PMREMGenerator(renderer),target=pmrem.fromScene(tour,0,.1,10);
 scene.environment=target.texture;scene.environmentIntensity=.55;setCampusEnvironment(target.texture);
 referenceScene.copy(tour);campusReflectionReady=true;pmrem.dispose();
});
const camera=new THREE.PerspectiveCamera(65,innerWidth/innerHeight,.12,180);
const referenceScene=new THREE.Scene(),referenceCamera=new THREE.PerspectiveCamera(70,innerWidth/innerHeight,.1,10);
const followRig=new FollowCamera();
let cameraYaw=0,cameraPitch=.30,cameraDistance=6.8,lastTurn=0;
const cameraRight=new THREE.Vector3(),cameraForward=new THREE.Vector3();
let looking=false,lastMouseX=0,lastMouseY=0;
const clampPitch=()=>cameraPitch=THREE.MathUtils.clamp(cameraPitch,.12,.85);
function rotateCamera(dx,dy){if(referenceMode){referenceYaw-=dx*.005;referencePitch=THREE.MathUtils.clamp(referencePitch+dy*.0035,-1.35,1.35);return;}cameraYaw-=dx*.005;cameraPitch+=dy*.0035;clampPitch();}
// Drag with the left/right mouse button, or click the viewport to lock the cursor.
renderer.domElement.addEventListener('pointerdown',e=>{
 if(e.button!==0 && e.button!==2)return;
 if(!running||(modal&&!referenceMode)||finished)return;
 looking=true;lastMouseX=e.clientX;lastMouseY=e.clientY;
 renderer.domElement.setPointerCapture?.(e.pointerId);
});
renderer.domElement.addEventListener('pointermove',e=>{
 if(document.pointerLockElement===renderer.domElement){rotateCamera(e.movementX,e.movementY);return;}
 if(!looking)return;
 rotateCamera(e.clientX-lastMouseX,e.clientY-lastMouseY);
 lastMouseX=e.clientX;lastMouseY=e.clientY;
});
renderer.domElement.addEventListener('pointerup',()=>looking=false);
renderer.domElement.addEventListener('pointercancel',()=>looking=false);
renderer.domElement.addEventListener('dblclick',()=>{if(running&&!modal)renderer.domElement.requestPointerLock?.()});
renderer.domElement.addEventListener('contextmenu',e=>e.preventDefault());
renderer.domElement.addEventListener('wheel',e=>{if(!running||modal||finished)return;e.preventDefault();cameraDistance=THREE.MathUtils.clamp(cameraDistance+Math.sign(e.deltaY)*.6,4.8,12);},{passive:false});
document.addEventListener('pointerlockchange',()=>{if(document.pointerLockElement!==renderer.domElement)looking=false;});
const hemi=new THREE.HemisphereLight('#e5f1fc','#5a5048',1.25);scene.add(hemi);
const sun=new THREE.DirectionalLight('#fff2d5',2.7);sun.position.set(-16,35,14);sun.castShadow=true;sun.shadow.mapSize.set(2048,2048);sun.shadow.camera.left=-34;sun.shadow.camera.right=34;sun.shadow.camera.top=34;sun.shadow.camera.bottom=-34;sun.shadow.camera.far=100;sun.shadow.bias=-.0006;sun.shadow.normalBias=.04;scene.add(sun);
const rim=new THREE.DirectionalLight('#59c6ff',1.2);rim.position.set(14,10,-18);scene.add(rim);
const playerLight=new THREE.PointLight('#8cf5ff',2.8,7,2);scene.add(playerLight);
const world=createWorld(scene),dressing=dressCampus(world),player=makeSphinx(scene),sky=createSky(scene),shock=createShockwave(scene);
scene.traverse(o=>{if(o.userData.wayfinding)o.visible=false;});
batchStaticMeshes(world.root);
const focus=new THREE.Vector3(0,0,4.1),desiredCamera=new THREE.Vector3(),velocity=new THREE.Vector2();
player.group.position.copy(focus);camera.position.set(0,4.8,13.1);camera.lookAt(0,1.2,4.1);
let running=false,finished=false,mapFound=false,shrineActive=false,anchorReleased=false,modal=null,interactTarget=null;
let reversals=0,elapsed=0,clock=0,last=performance.now(),reverseAt=-10,toastTimeout,sequence=[],sequenceLocked=false,sequenceResetAt=0,cinema=0,quality=true,waterNoticeAt=-10,qaWalking=false,introT=-1,jumpY=0,jumpV=0,landImpact=0;
const qaMode=new URLSearchParams(location.search).has('qa'),INTRO=5.5;
const introLines=[[0,'YOU ARE THE PHARAOH.'],[1.6,'NEFERTITI IS TRAPPED IN TIME.'],[3.5,'FIND THE THREE SACRED SEALS TO SAVE HER.']];
// Progression is reset entirely by start().
const ONE=new THREE.Vector3(1,1,1),keys=new Set(),reducedMotion=matchMedia('(prefers-reduced-motion: reduce)').matches;
const colorSunA=new THREE.Color('#fff2d5'),colorSunB=new THREE.Color('#ff9e55'),hemiA=new THREE.Color('#e5f1fc'),hemiB=new THREE.Color('#ffd7b0');
const notices={A:'SEAL A RESTORED · The archive remembers.',B:'SEAL B RESTORED · Every open path has a price.',C:'SEAL C RESTORED · What is hidden is not gone.'};
function resize(){const w=innerWidth,h=innerHeight;renderer.setSize(w,h);camera.aspect=w/h;camera.updateProjectionMatrix();referenceCamera.aspect=w/h;referenceCamera.updateProjectionMatrix();}
addEventListener('resize',resize);resize();
function toast(message,duration=3000){$('toast').textContent=message;$('toast').classList.add('active');clearTimeout(toastTimeout);toastTimeout=setTimeout(()=>$('toast').classList.remove('active'),duration);}
function clearInput(){keys.clear();velocity.set(0,0);looking=false;if(document.pointerLockElement===renderer.domElement)document.exitPointerLock?.();}
function setModal(id){if(modal)$(modal).classList.add('hidden');modal=id;referenceMode=id==='reference-view';clearInput();if(id)$(id).classList.remove('hidden');app.classList.toggle('paused',!!id);$('interaction').classList.add('hidden');if(id==='map-modal')updateMapText();}
function updateObjective(){const n=world.coins.filter(c=>c.picked).length;$('seal-count').textContent=`${n} / 3 RESTORED`;
 let chapter='01 / THE THREE SEALS',objective;
 if(n<3){const next=world.coins.find(c=>!c.picked);objective={A:'GO TO THE WESTERN ARCHIVE',B:'CROSS THE BRIDGE · FIND SEAL B',C:'ENTER THE AGORA · FIND SEAL C'}[next.id];}
 else if(!shrineActive){chapter='02 / THE SHRINE OF RETURN';objective='RETURN TO THE SOUTHERN SHRINE';}
 else if(!mapFound){chapter='03 / CELESTIAL CARTOGRAPHY';objective='R TO ANCIENT · E TO READ THE MAP';}
 else if(!anchorReleased){chapter='04 / THE QUEEN BETWEEN WORLDS';objective='ENTER THE NORTHERN SANCTUARY';}
 else{chapter='04 / THE LAST REVERSAL';objective='R TO ANCIENT · FREE NEFERTITI';}
 $('chapter').textContent=chapter;$('objective').textContent=objective;
}
function reverse(){if(!running||finished||modal||introT>=0||clock-reverseAt<.85)return;
 const next=!world.inAncient(),p=player.group.position;
 if(world.blocked(p.x,p.z,next)){toast('A wall would close around you. Step clear of the doorway first.');sound.error();return;}
 if(world.inWater(p.x,p.z,next)){toast('This bridge disappears in the present. Reach the round landing first.');sound.error();return;}
 world.setAncient(next);reality.trigger(p.x,p.z,next);reverseAt=clock;reversals++;dressing.reverse(p.x,p.z);sound.reverse(next);
 $('world-name').textContent=next?'ANCIENT ECHO':'PRESENT DAY';$('world-label').classList.toggle('ancient',next);
 const flash=$('crossfade');flash.classList.remove('active');flash.classList.toggle('ancient',next);void flash.offsetWidth;flash.classList.add('active');
 if(reversals===1)toast('THE ANCIENT ECHO · Paths return. Other doors close.',3500);
}
function findInteraction(){if(!running||finished||modal){interactTarget=null;$('interaction').classList.add('hidden');return;}
 const p=player.group.position;let best=null,min=2;
 for(const c of world.coins){if(c.picked||(c.id==='C'&&!world.inAncient()))continue;const d=Math.hypot(p.x-c.x,p.z-c.z);if(d<min){best={type:'coin',coin:c,label:`E  ·  RESTORE SEAL ${c.id}`};min=d;}}
 if(world.coins.every(c=>c.picked)&&Math.hypot(p.x,p.z-12.7)<2.7){if(!shrineActive)best={type:'shrine',label:'E  ·  OFFER THE THREE SEALS'};else if(!mapFound)best={type:'map',label:'E  ·  READ THE CELESTIAL MAP'};}
 if(mapFound&&!anchorReleased&&Math.hypot(p.x-2,p.z+22)<1.7)best={type:'anchor',label:world.inAncient()?'R  ·  THE ANCHOR EXISTS IN THE PRESENT':'E  ·  SEVER THE PRISON ANCHOR'};
 if(mapFound&&Math.hypot(p.x,p.z+24)<1.9)best={type:'rescue',label:!anchorReleased?'THE PRISON ANCHOR STILL HOLDS':world.inAncient()?'E  ·  BRING NEFERTITI HOME':'R  ·  REACH HER IN THE ANCIENT ECHO'};
 interactTarget=best;$('interaction').classList.toggle('hidden',!best);if(best)$('interaction').textContent=best.label;
}
function interact(){if(!running||finished||modal||introT>=0)return;findInteraction();const i=interactTarget;if(!i)return;
 if(i.type==='coin'){i.coin.picked=true;i.coin.pickT=0;dressing.reverse(i.coin.x,i.coin.z);$('c'+i.coin.id).classList.add('got');sound.collect();toast(notices[i.coin.id]);updateObjective();}
 if(i.type==='shrine'){sequence=[];sequenceLocked=false;sequenceResetAt=0;$('sequence').textContent='—  —  —';setModal('shrine-modal');}
 if(i.type==='map'){
  if(!world.inAncient()){toast('The parchment is blank in the present. Reverse reality to read it.');sound.error();return;}
  mapFound=true;sound.collect();updateObjective();setModal('map-modal');toast('THE MAP REMEMBERS · Nefertiti is in the northern sanctuary.',4500);
 }
 if(i.type==='anchor'){if(world.inAncient()){toast('Reverse to the present beside this anchor.');return;}anchorReleased=true;sound.collect();dressing.reverse(2,-22);toast('THE ANCHOR IS BROKEN · Return to the echo. Bring her home.',4500);updateObjective();}
 if(i.type==='rescue'){if(!anchorReleased){toast('Sever the glowing anchor beside Nefertiti. It can be touched only in the present.');sound.error();return;}if(!world.inAncient()){toast('One last reversal. She is waiting in the ancient echo.');return;}complete();}
 findInteraction();
}
function offer(s){if(modal!=='shrine-modal'||sequenceLocked)return;sequence.push(s);sound.offer(sequence.length-1);$('sequence').textContent=sequence.join('  →  ')+Array(Math.max(0,3-sequence.length)).fill('  —').join('');
 if(sequence.length===3){sequenceLocked=true;if(sequence.join('')==='CBA'){shrineActive=true;setModal(null);sound.collect();dressing.reverse(0,12.7);toast('THE SHRINE AWAKENS · Read the map in ancient light.',4200);updateObjective();}else{toast('The order must be reversed. Read from the end of A → B → C.');sound.error();sequenceResetAt=performance.now()+1100;
  setTimeout(()=>{if(sequenceLocked&&sequenceResetAt){sequence=[];sequenceLocked=false;sequenceResetAt=0;$('sequence').textContent='—  —  —';}},1100);}}
}
function updateMapText(){$('map-text').textContent=mapFound?'Nefertiti waits in the northern sanctuary. Enter in the ancient echo. Sever the anchor in the present. Return to the echo to bring her home.':'The three seals awaken the shrine south of Agora. Seek A in the western archive, B beyond the eastern bridge, and C in the ancient echo north of Agora.';$('map-modal').classList.toggle('revealed',mapFound);}
function complete(){if(!world.coins.every(c=>c.picked)||!shrineActive||!mapFound||!anchorReleased)return;finished=true;cinema=.001;player.group.userData.rescueStart=player.group.position.clone();clearInput();setModal(null);$('interaction').classList.add('hidden');app.classList.add('cinematic');$('cinematic-caption').classList.remove('hidden');sound.win();dressing.reverse(0,-24);
 // The curse breaks: one last wavefront rolls out from Nefertiti and restores the campus.
 setTimeout(()=>{if(!finished)return;world.setAncient(false);reality.speed=14;reality.trigger(0,-24,false);reverseAt=clock;sound.reverse(false);$('world-name').textContent='PRESENT DAY';$('world-label').classList.remove('ancient');},2600);}
function showVictory(){running=false;$('victory').classList.remove('hidden');$('cinematic-caption').classList.add('hidden');const secs=Math.max(1,Math.floor(elapsed));let best;try{const old=Number(localStorage.getItem('sphinx-best'))||Infinity;best=Math.min(old,secs);localStorage.setItem('sphinx-best',String(best));}catch{best=secs;}
 const fmt=s=>`${Math.floor(s/60)}:${String(s%60).padStart(2,'0')}`;const rank=secs<300&&reversals<=14?'PHARAOH OF REVERSAL':secs<480?'GUARDIAN OF TWO WORLDS':'KEEPER OF THE ECHO';
 $('stats').innerHTML=`<b class="rank">${rank}</b><br>RESCUE TIME ${fmt(secs)}   ·   ${reversals} REVERSALS   ·   BEST ${fmt(best)}`;
}
function start(){running=true;finished=false;mapFound=false;shrineActive=false;anchorReleased=false;reversals=0;elapsed=0;cinema=0;sequence=[];sequenceLocked=false;sequenceResetAt=0;reverseAt=-10;waterNoticeAt=-10;
 clearInput();setModal(null);world.setAncient(false);world.state.mix=0;reality.reset();reality.speed=24;jumpY=jumpV=landImpact=0;sound.init();sound.setAncient(false);$('world-label').classList.remove('ancient');$('world-name').textContent='PRESENT DAY';
 player.group.position.set(0,.10,4.1);player.group.rotation.y=Math.PI;cameraDistance=6.8;focus.copy(player.group.position);cameraYaw=0;cameraPitch=.30;camera.position.set(0,4.8,13.1);camera.zoom=1;camera.updateProjectionMatrix();
 for(const c of world.coins){c.picked=false;c.pickT=1;c.group.scale.setScalar(1);$('c'+c.id).classList.remove('got');}world.update(0,clock);dressing.update(0,clock,0,{});
 $('intro').classList.add('hidden');$('victory').classList.add('hidden');$('cinematic-caption').classList.add('hidden');app.classList.remove('cinematic');app.classList.add('playing');updateObjective();
 if(qaMode&&!new URLSearchParams(location.search).has('intro')){introT=-1;endIntro();}else{introT=0;app.classList.add('cinematic');$('cinematic-caption').classList.remove('hidden');$('skip-intro').classList.remove('hidden');}
}
// The intro flies over the real Agora frontage and previews one reversal, then hands over control.
function endIntro(){const wasIntro=introT>=0;introT=-2;app.classList.remove('cinematic');$('cinematic-caption').classList.add('hidden');$('skip-intro').classList.add('hidden');
 if(world.inAncient()){world.setAncient(false);reality.trigger(player.group.position.x,player.group.position.z,false);sound.setAncient(false);}
 $('world-label').classList.remove('ancient');$('world-name').textContent='PRESENT DAY';if(wasIntro)camera.fov=65;
 toast('FIND THREE SEALS · Follow the gold marker. R reverses reality.',3500);}
function updateIntro(rawDt){introT+=rawDt;const t=introT;
 if(t>1.2&&t<3.2&&!world.inAncient()){world.setAncient(true);reality.trigger(0,4.1,true);dressing.reverse(0,4.1);sound.reverse(true);reverseAt=clock;}
 if(t>3.5&&world.inAncient()){world.setAncient(false);reality.trigger(0,4.1,false);dressing.reverse(0,4.1);sound.reverse(false);reverseAt=clock;}
 let line='';for(const [at,text] of introLines)if(t>=at)line=text;$('cinematic-caption').textContent=line;
 const P0=[3.2,3.0,10],P1=[1.5,3.2,11],P2=[0,3.1,11.5],L0=[0,1.1,4.1],L1=[0,1.4,2.0],L2=[0,1.1,4.1];
 const u=Math.min(1,t/INTRO),first=u<.55,a=first?THREE.MathUtils.smootherstep(u/.55,0,1):THREE.MathUtils.smootherstep((u-.55)/.45,0,1),[A,B,LA,LB]=first?[P0,P1,L0,L1]:[P1,P2,L1,L2];
 camera.position.set(A[0]+(B[0]-A[0])*a,A[1]+(B[1]-A[1])*a,A[2]+(B[2]-A[2])*a);desiredCamera.copy(camera.position);
 camera.lookAt(LA[0]+(LB[0]-LA[0])*a,LA[1]+(LB[1]-LA[1])*a,LA[2]+(LB[2]-LA[2])*a);
 if(t>=INTRO)endIntro();}
// Shared by keyboard movement and the development-only deterministic collision replay.
function moveVector(dx,dz,dt,sprint=false){if(!running||finished||modal)return;const moving=Math.hypot(dx,dz)>.01,speed=sprint?6.7:4.5;
 if(moving){const length=Math.hypot(dx,dz);dx=dx/length*speed;dz=dz/length*speed;}else{dx=0;dz=0;}
 velocity.x=THREE.MathUtils.damp(velocity.x,dx,moving?12:28,dt);velocity.y=THREE.MathUtils.damp(velocity.y,dz,moving?12:28,dt);
 const p=player.group.position,startX=p.x,startZ=p.z,substeps=3;
 for(let i=0;i<substeps;i++){const nx=p.x+velocity.x*dt/substeps,nz=p.z+velocity.y*dt/substeps;
  const waterX=world.inWater(nx,p.z),waterZ=world.inWater(p.x,nz);
  if(!world.blocked(nx,p.z)&&!waterX)p.x=nx;else velocity.x=0;
  if(!world.blocked(p.x,nz)&&!waterZ)p.z=nz;else velocity.y=0;
  if((waterX||waterZ)&&clock-waterNoticeAt>3){toast('THE BRIDGE IS BROKEN · R restores a real crossing.');waterNoticeAt=clock;sound.error();}

 }
 if(moving){let target=Math.atan2(-dx,-dz),difference=THREE.MathUtils.euclideanModulo(target-player.group.rotation.y+Math.PI,Math.PI*2)-Math.PI;lastTurn=difference;player.group.rotation.y+=difference*(1-Math.exp(-dt*12));}
 player.animate(dt,Math.hypot(p.x-startX,p.z-startZ)/Math.max(dt,.001),clock,lastTurn,{height:jumpY,verticalVelocity:jumpV,landing:landImpact});
 const px=player.group.position.x,pz=player.group.position.z;
 const floor=world.agora.isInside(px,pz)?.13:world.inAncient()&&px>8.12&&px<12.1&&Math.abs(pz+7)<1.5?.33:Math.abs(px)<3.6&&pz< -19&&pz> -27?.08:Math.abs(px)<14&&pz> -10.9&&pz<17.1?.10:0;
 player.group.position.y=floor+jumpY;

}
function move(dt){
 landImpact=THREE.MathUtils.damp(landImpact,0,12,dt);
 if(jumpY>0||jumpV>0){jumpV-=15*dt;jumpY=Math.max(0,jumpY+jumpV*dt);if(jumpY===0){jumpV=0;landImpact=1;player.ring.scale.setScalar(1.45);sound.land();}}
 player.ring.scale.lerp(ONE,1-Math.exp(-dt*6));
 const x=Number(keys.has('d')||keys.has('arrowright'))-Number(keys.has('a')||keys.has('arrowleft'));
 const z=Number(keys.has('w')||keys.has('arrowup'))-Number(keys.has('s')||keys.has('arrowdown'));
 camera.getWorldDirection(cameraForward);cameraForward.y=0;cameraForward.normalize();
 cameraRight.crossVectors(cameraForward,THREE.Object3D.DEFAULT_UP).normalize();
 moveVector(cameraRight.x*x+cameraForward.x*z,cameraRight.z*x+cameraForward.z*z,dt,keys.has('shift'));
}
function updateLocation(){const {x,z}=player.group.position;let name='AGORA CIRCLE',hint='The western archive holds the first seal. Follow the map to your right.';
 if(world.agora.isInside(x,z)){name='INSIDE LAKEHEAD AGORA';hint='You entered the Agora. Explore the atrium, find the hidden seal in the echo (R), or turn and walk outside.';}
 else if(z<-18){name='THE QUEEN BETWEEN WORLDS';hint=!mapFound?'Her sanctuary is silent. Awaken the shrine first.':!anchorReleased?'The echo opens the entrance. The present reveals the prison anchor.':'The anchor is broken. One final reversal brings her home.';}
 else if(z<-10&&Math.abs(x)<6){name='THE UNSEEN CONSTELLATION';hint=world.coins[2].picked?'The stars remember. Return the seals to the southern shrine.':'Some things only exist in ancient light. Press R.';}
 else if(x<-8&&z<-2){name='THE WESTERN ARCHIVE';hint=world.coins[0].picked?'The first seal is yours. The bridge lies east of Agora.':world.inAncient()?'The old doorway is open. Step inside the archive.':'A sealed doorway. What if the past remembers it open?';}
 else if(x>6&&z<-2){name='BRIDGE OF OPPOSITES';hint=x<12.2?'The ancient echo restores the bridge. Cross to the round landing.':world.inAncient()?'The bridge is whole, but the gate is sealed. Reverse on solid ground.':'The gate is open; the bridge is gone. Take the seal, then retrace your reversals.';}
 else if(z>9){name='THE SHRINE OF RETURN';hint=!world.coins.every(c=>c.picked)?'The shrine waits for three sacred seals.':!shrineActive?'An inscription: A → B → C. The past asks you to return them.':!mapFound?'An unreadable map. Ancient light will reveal its meaning.':'The queen waits to the north. Open the map with M.';}
 else if(world.coins[0].picked)hint=mapFound?'Follow the cyan diamond north to the sanctuary.':'The map marks the seals and the shrine. Every reversal changes the way forward.';
 $('location-name').textContent=name;$('local-hint').textContent=hint;
}

function missionTarget(){
 const p=player.group.position,a=world.inAncient(),next=world.coins.find(c=>!c.picked);
 if(next?.id==='A')return {x:a?-16.8:-10,z:-7,name:'WESTERN ARCHIVE',hint:a?'E · COLLECT SEAL A':'R · OPEN THE ANCIENT DOOR'};
 if(next?.id==='B'){
  if(p.x<8)return {x:7.4,z:-7,name:'BRIDGE ENTRY',hint:a?'CROSS TO THE ROUND LANDING':'R · RESTORE THE BRIDGE'};
  if(p.x<12.5||a)return {x:13.3,z:-7,name:'SAFE LANDING',hint:p.x>12.2?'R · OPEN THE PRESENT-DAY GATE':'CROSS TO THE LANDING'};
  return {x:18.4,z:-7,name:'SEAL B',hint:'E · COLLECT SEAL B'};
 }
 if(next?.id==='C'&&p.x>8)return {x:a?7:13.3,z:-7,name:a?'RETURN ACROSS BRIDGE':'SAFE LANDING',hint:a?'CROSS BACK TO AGORA':'R · RESTORE THE RETURN BRIDGE'};
 if(next?.id==='C')return {x:0,z:p.z> -9.2&&Math.abs(p.x)>1.3?-8:-13.5,name:'AGORA ATRIUM / C',hint:a?'E · COLLECT SEAL C':'R · REVEAL THE HIDDEN SEAL'};
 if(!shrineActive||!mapFound){if(p.z< -9.5)return {x:0,z:-8,name:'AGORA EXIT',hint:'RETURN THROUGH THE MAIN DOORS'};return {x:0,z:12.7,name:'SHRINE OF RETURN',hint:!shrineActive?'E · OFFER C → B → A':a?'E · READ THE MAP':'R · REVEAL THE MAP'};}
 if(!anchorReleased){if(p.z> -9.3)return {x:0,z:-8,name:'AGORA ENTRANCE',hint:'WALK THROUGH THE MAIN DOORS'};if(p.z> -19)return {x:0,z:-18,name:'SANCTUARY GATE',hint:a?'ENTER THE SANCTUARY':'R · OPEN THE SANCTUARY'};return {x:2,z:-22,name:'TEMPORAL ANCHOR',hint:a?'R · REVEAL THE ANCHOR IN THE PRESENT':'E · BREAK THE PRISON ANCHOR'};}
 return {x:0,z:-24,name:'NEFERTITI',hint:a?'E · FREE NEFERTITI':'R · REACH HER IN THE ANCIENT ECHO'};
}
const markerPoint=new THREE.Vector3();
function updateMissionMarker(){const el=$('mission-marker');el.classList.toggle('hidden',!!modal||finished||introT>=0);const t=missionTarget(),p=player.group.position,d=Math.hypot(t.x-p.x,t.z-p.z);markerPoint.set(t.x,1.6,t.z);const local=markerPoint.clone().applyMatrix4(camera.matrixWorldInverse);markerPoint.project(camera);let x=(markerPoint.x*.5+.5)*innerWidth,y=(-markerPoint.y*.5+.5)*innerHeight;if(local.z>0){x=local.x>0?innerWidth-35:35;y=innerHeight*.5;}x=THREE.MathUtils.clamp(x,36,innerWidth-36);y=THREE.MathUtils.clamp(y,160,innerHeight-140);el.style.left=x+'px';el.style.top=y+'px';el.querySelector('small').textContent=Math.round(d)+'m';$('mission-distance').textContent=d<3.4?t.hint:t.name+' · '+Math.round(d)+'m';}

const mapCtx=$('minimap').getContext('2d');
function drawMap(){const c=mapCtx,k=world.inAncient();c.clearRect(0,0,220,220);const point=(x,z)=>[110+x*3.5,118+z*3];c.strokeStyle='#68859945';c.lineWidth=1;c.strokeRect(22,29,176,151);c.beginPath();c.arc(110,135,23,0,Math.PI*2);c.stroke();c.setLineDash([3,4]);c.beginPath();c.moveTo(110,45);c.lineTo(110,163);c.moveTo(42,97);c.lineTo(178,97);c.stroke();c.setLineDash([]);c.fillStyle='#8eacbd';c.font='10px Arial';c.textAlign='center';c.fillText('N',110,18);
 for(const s of world.coins){const [x,y]=point(s.x,s.z);c.fillStyle=s.picked?'#76b8a2':s.id==='C'&&!k?'#617886':'#e8bf70';c.beginPath();c.arc(x,y,s.picked?2:5,0,Math.PI*2);c.fill();c.fillText(s.id,x,y-10);}
 const [sx,sy]=point(0,12.7);c.fillStyle=shrineActive?'#9aede1':'#e8bf70';c.fillRect(sx-4,sy-4,8,8);c.fillText('SHRINE',sx,sy+17);
 if(mapFound){const [qx,qy]=point(0,-24);c.fillStyle='#84efe8';c.beginPath();c.moveTo(qx,qy-7);c.lineTo(qx+5,qy);c.lineTo(qx,qy+7);c.lineTo(qx-5,qy);c.fill();}
 const [px,py]=point(player.group.position.x,player.group.position.z);c.fillStyle='#fff8df';c.shadowColor='#ffffff';c.shadowBlur=8;c.beginPath();c.arc(px,py,4,0,Math.PI*2);c.fill();c.shadowBlur=0;
}
$('tour-reference').onclick=()=>{if(campusReflectionReady)setModal('reference-view');else toast('Preparing the local Agora photographs…');};$('close-reference').onclick=()=>setModal('pause-modal');
$('skip-intro').onclick=()=>{if(introT>=0)endIntro();};$('start').onclick=start;$('restart').onclick=start;$('reset-pause').onclick=start;$('resume').onclick=()=>setModal(null);$('close-shrine').onclick=()=>setModal(null);$('close-map').onclick=()=>setModal(null);
for(const b of document.querySelectorAll('[data-seal]'))b.onclick=()=>offer(b.dataset.seal);
function toggleAudio(){const muted=sound.toggle();$('audio-toggle').textContent=muted?'SOUND OFF':'SOUND ON';$('audio-toggle').setAttribute('aria-label',muted?'Unmute audio':'Mute audio');}
$('audio-toggle').onclick=toggleAudio;$('help-toggle').onclick=()=>{if(running&&!finished)setModal(modal?null:'pause-modal');};
$('quality-toggle').onclick=()=>{quality=!quality;renderer.setPixelRatio(quality?Math.min(devicePixelRatio,1.5):1);renderer.shadowMap.enabled=quality;scene.traverse(o=>{if(o.material)o.material.needsUpdate=true;});$('quality-toggle').textContent=quality?'QUALITY HIGH':'QUALITY LOW';resize();};
addEventListener('keydown',e=>{const k=e.key.toLowerCase();if(['arrowup','arrowdown','arrowleft','arrowright',' '].includes(k))e.preventDefault();if(e.repeat)return;
 if(k==='v'){toggleAudio();return;}if(k==='escape'&&running&&!finished&&introT<0){setModal(modal?null:'pause-modal');return;}
 if(k==='m'&&running&&!finished&&introT<0){setModal(modal==='map-modal'?null:'map-modal');return;}
 if(modal){if(modal==='shrine-modal'&&['a','b','c'].includes(k))offer(k.toUpperCase());return;}
 if(introT>=0){if(k===' '||k==='enter'||k==='escape')endIntro();return;}
 if(k==='r'||k==='q')reverse();else if(k==='e')interact();else if(k===' '){if(jumpY===0&&running&&!finished){jumpV=5.6;jumpY=.001;}}else keys.add(k);
});addEventListener('keyup',e=>keys.delete(e.key.toLowerCase()));addEventListener('blur',clearInput);
addEventListener('visibilitychange',()=>{clearInput();if(document.hidden){sound.suspend();if(running&&!finished&&!modal)setModal('pause-modal');}else sound.resume();});
function animate(now){requestAnimationFrame(animate);const rawDt=Math.min(.25,(now-last)/1000),dt=Math.min(.1,rawDt);last=now;clock+=rawDt;
 if(running&&introT>=0)updateIntro(rawDt);
 else if(running&&!finished&&!modal&&!document.hidden){elapsed+=rawDt;if(!qaWalking)move(dt);}
 reality.update(dt,clock);shock.update();
 if(sequenceLocked&&sequenceResetAt&&now>=sequenceResetAt){sequence=[];sequenceLocked=false;sequenceResetAt=0;$('sequence').textContent='—  —  —';}
 world.update(dt,clock,player.group.position);const mix=world.state.mix;dressing.update(reducedMotion?Math.min(dt,.025):dt,clock,mix,{anchorReleased,rescued:finished});
 sun.color.copy(colorSunA).lerp(colorSunB,mix);hemi.intensity=1.25-mix*.1;hemi.color.copy(hemiA).lerp(hemiB,mix);rim.intensity=1.3+mix*.3;rim.color.set(mix>.5?'#a798ff':'#59c6ff');
 if(finished||modal||introT>=0||!running)player.animate(dt,0,clock,0);player.ring.rotation.z=clock*.2;playerLight.position.copy(player.group.position);playerLight.position.y=2.5;
 if(running&&!finished&&introT<0){findInteraction();updateLocation();drawMap();updateMissionMarker();}
 const targetFocus=finished?new THREE.Vector3(0,1,-24):player.group.position;
 focus.lerp(targetFocus,1-Math.exp(-dt*6));
 if(finished){cinema+=rawDt;const t=Math.min(cinema/7,1),a=reducedMotion?.6:.6+cinema*.09;player.group.position.x=THREE.MathUtils.damp(player.group.position.x,-1.65,3,dt);player.group.position.z=THREE.MathUtils.damp(player.group.position.z,-23.7,3,dt);player.group.rotation.y=THREE.MathUtils.damp(player.group.rotation.y,Math.PI,4,dt);desiredCamera.set(focus.x+1.5,focus.y+2.1,focus.z+3.8);camera.zoom=THREE.MathUtils.damp(camera.zoom,1,3,dt);camera.updateProjectionMatrix();$('cinematic-caption').textContent=cinema<2.6?'“I knew you would find a way through.”':cinema<4.6?'The curse of the Sphinx is broken.':'Two worlds. One way home.';if(cinema>7&&running)showVictory();}
 else if(introT<0){
  const inside=world.agora.isInside(player.group.position.x,player.group.position.z);
  const anchor=player.group.position.clone().add(new THREE.Vector3(0,1.35,0));
  followRig.update(camera,anchor,cameraYaw,cameraPitch,inside?Math.min(cameraDistance,5.3):cameraDistance,cameraVolumes(world),dt);
 }
 if(introT<0&&finished){camera.position.lerp(desiredCamera,1-Math.exp(-dt*5));camera.lookAt(focus.x,focus.y+1.18,focus.z);}
 // Reversal camera feedback: a short FOV punch that breathes back out.
 {const r=clock-reverseAt,kick=r<1.1&&!reducedMotion?Math.sin(r/1.1*Math.PI)*(1-r/1.1)*16:0;camera.fov=65+kick;camera.updateProjectionMatrix();}
 if(!reducedMotion&&clock-reverseAt<.8){const f=1-(clock-reverseAt)/.8,shake=.09*f*f;camera.position.x+=Math.sin((clock-reverseAt)*37)*shake;camera.position.y+=Math.cos((clock-reverseAt)*29)*shake*.7;}
 if(introT<0&&!finished)followRig.enforce(camera);
 sun.position.set(focus.x-16,35,focus.z+14);sun.target.position.copy(focus);sun.target.updateMatrixWorld();sky.update(mix,clock,camera);if(referenceMode){referenceCamera.rotation.order='YXZ';referenceCamera.rotation.set(referencePitch,referenceYaw,0);renderer.render(referenceScene,referenceCamera);}else renderer.render(scene,camera);
}requestAnimationFrame(animate);

// Opt-in QA adapter for local test builds (?qa); never activated during normal play.
if(new URLSearchParams(location.search).has('qa'))window.__sphinxQA={
 snapshot:()=>({canReverse:clock-reverseAt>=.85,intro:introT>=0,jumpY,x:player.group.position.x,z:player.group.position.z,insideAgora:world.agora.isInside(player.group.position.x,player.group.position.z),doorOpen:Math.abs(world.agora.doors[0].leaf.position.x)>1.6,cameraYaw,cameraHeading:Math.atan2(-camera.getWorldDirection(new THREE.Vector3()).x,-camera.getWorldDirection(new THREE.Vector3()).z),cameraDistance,model:player.model,heroType:player.heroType,campusReflectionReady,cameraClearance:followRig.clearance,cameraObstructed:followRig.obstructed,cameraAutomaticOrbit:followRig.automaticOrbit,cameraCollisionSafe:clipCamera(followRig.anchor,camera.position,followRig.boxes).fraction>.999,referenceMode,legCount:player.legs.length,ancient:world.inAncient(),coins:world.coins.filter(c=>c.picked).map(c=>c.id),shrineActive,mapFound,anchorReleased,finished,modal,reversals,elapsed,drawCalls:renderer.info.render.calls,triangles:renderer.info.render.triangles}),
 walk:(x,z)=>{qaWalking=true;clearInput();for(let i=0;i<1800;i++){const p=player.group.position,dx=x-p.x,dz=z-p.z;if(Math.hypot(dx,dz)<.09)break;moveVector(dx,dz,1/60,false);world.update(1/60,clock,player.group.position);}clearInput();qaWalking=false;findInteraction();return {x:player.group.position.x,z:player.group.position.z};},
 settle:()=>{reverseAt=-10;world.update(2,clock);},world,
 inspect:()=>({camera:camera.position.toArray(),player:player.group.position.toArray(),render:renderer.info.render}),
 rotateCamera:(dx,dy=0)=>rotateCamera(dx,dy)
};
