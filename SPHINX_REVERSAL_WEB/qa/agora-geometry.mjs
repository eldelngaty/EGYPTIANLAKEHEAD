// Headless deterministic Three.js geometry/collision tests (no fake browser claims).
import assert from 'node:assert/strict';
// World textures use a canvas, but physics can run headless with a 2D canvas stub.
const noop=()=>{},gradient={addColorStop:noop};
const ctx=new Proxy({},{get:(t,k)=>k in t?t[k]:k==='createImageData'?(w,h)=>({data:new Uint8ClampedArray(w*h*4)}):/Gradient$/.test(k)?()=>gradient:noop,set:(t,k,v)=>(t[k]=v,true)});
globalThis.document={createElement(tag){return tag==='link'?{relList:{supports:()=>true}}:{width:1024,height:512,getContext:()=>ctx}}};
const THREE=await import('../vendor/three.module.min.js');
const {createWorld}=await import('../src/world.js');
const scene=new THREE.Scene();scene.background=new THREE.Color('#1d3856');scene.fog=new THREE.Fog('#1d3856',30,95);const world=createWorld(scene);
const testNames=[];
const check=(description,condition)=>{assert(condition,description);testNames.push(description);console.log('PASS',description)};
const radius=.35;
let player={x:0,z:4.1};
function moveToward(x,z){
 for(let i=0;i<3000;i++){
  const dx=x-player.x,dz=z-player.z,dist=Math.hypot(dx,dz);
  if(dist<.06)return;
  const step=Math.min(.048,dist),nx=player.x+dx/dist*step,nz=player.z+dz/dist*step;
  if(!world.blocked(nx,player.z))player.x=nx;
  if(!world.blocked(player.x,nz))player.z=nz;
 }
 throw Error(`Blocked approaching ${x},${z}, from ${JSON.stringify(player)}`);
}
check('Player spawns on outdoor Agora Circle',!world.blocked(0,4.1)&&!world.agora.isInside(0,4.1));
check('Main facade has solid walls on both sides',world.blocked(-4,-9.55)&&world.blocked(4,-9.55));
check('Main Agora entrance is actually open for traversal',!world.blocked(0,-9.55));
check('Player cannot pass the facade except through the doorway',world.blocked(5,-10)&&!world.blocked(0,-10));
moveToward(0,-8.5);for(let t=0;t<100;t++)world.update(.016,t*.016,new THREE.Vector3(player.x,0,player.z));
check('Entrance doors automatically slide open on approach',world.agora.doors[0].leaf.position.x<-2.08&&world.agora.doors[1].leaf.position.x>2.08);
moveToward(0,-13.5);
check('Player crosses threshold into collision-enabled Agora atrium',world.agora.isInside(player.x,player.z));
moveToward(5,-13.5);moveToward(5,-15.5);moveToward(-4,-15.5);
check('Player can explore the interior laterally',world.agora.isInside(player.x,player.z));
check('Interior side walls have real collision',world.blocked(9,-14)&&world.blocked(-9,-14));
check('Atrium rear walls block but central exit remains passable',world.blocked(4,-18.15)&&!world.blocked(0,-18.15));
moveToward(0,-12);moveToward(0,-6);moveToward(0,4.1);
check('Player can turn and exit to outdoor Agora Circle',!world.agora.isInside(player.x,player.z));
for(let t=0;t<100;t++)world.update(.016,t*.016,new THREE.Vector3(player.x,0,player.z));
check('Doors close after player walks away',Math.abs(world.agora.doors[0].leaf.position.x)<.85);
check('Original west seal gate still blocks in modern mode',world.blocked(-10,-7));
check('Original east gate opens in modern mode',!world.blocked(15.4,-7));
check('Original queen barrier blocks in modern mode',world.blocked(0,-19));
world.setAncient(true);
check('Original west gate opens after reversal',!world.blocked(-10,-7));
check('Original east gate closes in the ancient echo',world.blocked(15.4,-7));
check('Original queen barrier opens after reversal',!world.blocked(0,-19));
check('All three original story seals retain their positions',world.coins.length===3&&world.coins.find(x=>x.id==='C').z===-13.5);
// Regression traversal via original puzzle locations. Walk around the new facade,
// rather than assuming one can pass through its side walls.
world.setAncient(false);player={x:0,z:4.1};
moveToward(-6,4);moveToward(-6,-7);
world.setAncient(true);moveToward(-10,-7);moveToward(-16.8,-7);
check('Western archive/seal A remains physically reachable in ancient mode',Math.hypot(player.x+16.8,player.z+7)<.1);
moveToward(-10,-7);moveToward(-6,-7);moveToward(7,-7);moveToward(10,-7);moveToward(13.3,-7);
check('Rebuilt ancient bridge still crosses the former water',!world.inWater(player.x,player.z));
world.setAncient(false);moveToward(18.4,-7);
check('East seal B remains physically reachable from the landing',Math.hypot(player.x-18.4,player.z+7)<.1);
moveToward(13.3,-7);world.setAncient(true);moveToward(7,-7);moveToward(0,-7);moveToward(0,-13.5);
check('Hidden seal C remains physically reachable INSIDE reconstructed Agora',Math.hypot(player.x,player.z+13.5)<.1&&world.agora.isInside(player.x,player.z));
moveToward(0,10.6);
check('Original shrine of return remains reachable after exiting Agora',Math.hypot(player.x,player.z-10.6)<.1);
moveToward(0,-17);moveToward(0,-22);
check('Queen area still accessible through the rear of Agora in ancient mode',Math.hypot(player.x,player.z+22)<.1);

console.log(JSON.stringify({passed:testNames.length,physicsRoute:'outside -> main doors -> atrium sides -> main doors -> outside',browserRendered:false},null,2));
