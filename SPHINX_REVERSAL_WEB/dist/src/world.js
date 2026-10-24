import * as THREE from '../vendor/three.module.min.js';
import {makeGuardian} from './sphinx.js';
import {createAgoraCampus} from './agora.js';
import {patchReality,reality} from './reality.js';

export const PALETTE = {
  modernSky: new THREE.Color('#88b7dc'),
  ancientSky: new THREE.Color('#66547b'),
  modernFog: new THREE.Color('#c4d8ea'),
  ancientFog: new THREE.Color('#c27a55'),
};
const makeMat = (hex, extra = {}) => new THREE.MeshStandardMaterial({color:hex,roughness:.8,...extra});
const mats = {
  sandstone:makeMat('#c7a46b'), warmStone:makeMat('#e3bf78'), darkStone:makeMat('#665748'),
  gold:makeMat('#dfb55f',{metalness:.58,roughness:.33}),blue:makeMat('#256b91',{metalness:.2}),
  brick:makeMat('#6b4950'), cement:makeMat('#c5c6b9'), glass:makeMat('#5194a6',{metalness:.4,roughness:.25}),
  wood:makeMat('#6f4e36'), grass:patchReality(makeMat('#4f6b3c'),{strength:.95}), road:makeMat('#667986'),
  glow:new THREE.MeshStandardMaterial({color:'#ffe4a7',emissive:'#ffc86a',emissiveIntensity:1.9,roughness:.35}),
  egyptGlow:new THREE.MeshStandardMaterial({color:'#55ddd3',emissive:'#1eb2bd',emissiveIntensity:1.3}),
  water:makeMat('#1f6f95',{metalness:.5,roughness:.12,emissive:'#0b3a55',emissiveIntensity:.6}), shadow:makeMat('#233a38')
};
export function box(group,x,y,z,w,h,d,material){const m=new THREE.Mesh(new THREE.BoxGeometry(w,h,d),material);m.position.set(x,y,z);m.receiveShadow=true;m.castShadow=true;group.add(m);return m}
export function cylinder(group,x,y,z,rTop,rBottom,h,mat,n=8){const m=new THREE.Mesh(new THREE.CylinderGeometry(rTop,rBottom,h,n),mat);m.position.set(x,y,z);m.castShadow=true;m.receiveShadow=true;group.add(m);return m}
export function planeLabel(text,color='#f9dfb5',back='#1d3540',width=7,height=1.05){const c=document.createElement('canvas');c.width=1024;c.height=170;let g=c.getContext('2d');g.fillStyle=back;g.fillRect(0,0,c.width,c.height);g.lineWidth=9;g.strokeStyle='#c3a765';g.strokeRect(10,10,1004,150);g.fillStyle=color;g.font='bold 66px Georgia';g.textAlign='center';g.textBaseline='middle';g.fillText(text.replaceAll('𓂀','◈'),512,85,980);const tex=new THREE.CanvasTexture(c);tex.colorSpace=THREE.SRGBColorSpace;const material=new THREE.MeshBasicMaterial({map:tex,side:THREE.FrontSide,transparent:true});const m=new THREE.Mesh(new THREE.PlaneGeometry(width,height),material);m.userData.wayfinding=true;return m}
export function makeSphinx(root){return makeGuardian(root);}
export function makeNefertiti(root,x,z){
 const g=new THREE.Group();g.name='Nefertiti / royal blue crown';g.position.set(x,0,z);root.add(g);
 const dress=makeMat('#2b6d91'),gold=makeMat('#e6c376',{metalness:.48,roughness:.4}),skin=makeMat('#bb8c65'),linen=makeMat('#e5dfca');
 cylinder(g,0,.68,0,.23,.41,1.27,linen,16);cylinder(g,0,1.25,0,.29,.23,.44,skin,12);
 const head=new THREE.Mesh(new THREE.SphereGeometry(.25,16,12),skin);head.position.y=1.68;head.scale.set(.85,1.18,.87);head.castShadow=true;g.add(head);
 // Nefertiti's tall, flat-topped crown flares upward.
 cylinder(g,0,2.03,0,.36,.22,.57,dress,16);cylinder(g,0,2.32,0,.36,.36,.045,gold,16);cylinder(g,0,1.75,0,.22,.22,.065,gold,16);box(g,0,2.04,.263,.035,.49,.025,gold);
 cylinder(g,0,1.45,0,.34,.30,.12,gold,16);cylinder(g,0,1.44,0,.32,.29,.045,dress,16);
 for(const side of [-1,1]){box(g,side*.084,1.71,.213,.075,.022,.026,mats.shadow);box(g,side*.085,1.75,.204,.10,.022,.023,mats.shadow);cylinder(g,side*.20,1.56,0,.027,.035,.16,gold,8);const arm=cylinder(g,side*.34,1.19,0,.068,.055,.55,skin,10);arm.rotation.z=side*.12;cylinder(g,side*.36,.98,0,.073,.073,.065,gold,10);const hand=new THREE.Mesh(new THREE.SphereGeometry(.065,10,7),skin);hand.position.set(side*.37,.87,0);g.add(hand);box(g,side*.11,.07,.10,.17,.10,.29,gold);}
 box(g,0,1.66,.245,.043,.10,.035,skin);box(g,0,1.58,.205,.10,.017,.018,makeMat('#704431'));
 for(let i=0;i<11;i++){const a=(i-5)*.17;box(g,Math.sin(a)*.30,.71,.30*Math.cos(a),.014,1.10,.02,gold);}
 const halo=new THREE.Mesh(new THREE.TorusGeometry(.75,.025,5,45),mats.glow);halo.position.y=1.35;g.add(halo);
 return {group:g,halo};
}
export function createWorld(scene){
 const root=new THREE.Group();scene.add(root);
 // Subtle procedural ground grain. No network texture or external asset request.
 const grainCanvas=document.createElement('canvas');grainCanvas.width=grainCanvas.height=128;
 const gc=grainCanvas.getContext('2d'),pixels=gc.createImageData(128,128);
 for(let i=0;i<128*128;i++){const x=i%128,y=Math.floor(i/128),value=210+Math.sin(x*8.31+y*3.17)*15+Math.sin(y*.45+Math.sin(x*.14))*9;pixels.data.set([value,value,value,255],i*4);}
 gc.putImageData(pixels,0,0);const grain=new THREE.CanvasTexture(grainCanvas);grain.wrapS=grain.wrapT=THREE.RepeatWrapping;grain.repeat.set(14,14);grain.colorSpace=THREE.SRGBColorSpace;mats.grass.map=grain;mats.grass.bumpMap=grain;mats.grass.bumpScale=.07;

 const ground=box(root,0,-.32,-4,50,.6,53,mats.grass);
 box(root,0,.02,0,5,.06,32,mats.road);box(root,0,.023,7,43,.06,3,mats.road);
 box(root,0,.03,-12,22,.06,3,mats.road);
 // This is the single, real-reference-based Agora Circle + connected atrium.
 const agora=createAgoraCampus(root);
 const ancient=new THREE.Group();root.add(ancient);
 // Temple overlay: pillars & giant obelisks appear in the ancient echo.
 const columns=[];
 for(const x of [-5,5])for(const z of [-1.6,-4.7,-8.1]){
  const g=new THREE.Group();ancient.add(g);g.position.set(x,0,z);cylinder(g,0,1.65,0,.39,.53,3.3,mats.sandstone,10);cylinder(g,0,3.38,0,.62,.62,.33,mats.gold,10);g.userData.dynamic=true;columns.push(g)
 }
 for(let x of [-9.3,9.3]){
  const o=new THREE.Group();o.position.set(x,0,-15);ancient.add(o);box(o,0,1.35,0,1.2,2.7,1.2,mats.sandstone);const tip=new THREE.Mesh(new THREE.ConeGeometry(.82,1.8,4),mats.gold);tip.rotation.y=Math.PI/4;tip.position.y=3.55;o.add(tip);o.userData.dynamic=true;columns.push(o)
 }
 for(let x of [-4,4])for(let z of [-10,-17]){
   const glyph=cylinder(ancient,x,.07,z,.51,.51,.05,mats.egyptGlow,6);glyph.rotation.y=Math.PI/6;
 }
 // The Great Sphinx of the echo reclines on the west plaza, gazing at Agora Circle.
 // It is solid only in the ancient world, so reversal is refused while standing in it.
 {const g=new THREE.Group();g.position.set(-11,0,9);ancient.add(g);g.userData.dynamic=true;columns.push(g);
  box(g,0,.35,0,6.6,.7,3.4,mats.darkStone);
  box(g,-.6,1.35,0,5.0,1.5,2.4,mats.sandstone);
  for(const z of [-.75,.75])box(g,2.55,.95,z,2.3,.5,.62,mats.sandstone);
  const head=new THREE.Group();head.position.set(1.25,2.75,0);g.add(head);
  // Striped nemes headdress, sandstone face, kohl-lined glowing eyes and beard.
  const nemes=new THREE.Mesh(new THREE.CylinderGeometry(.5,.95,1.6,4),mats.gold);nemes.rotation.y=Math.PI/4;nemes.position.set(-.1,0,0);head.add(nemes);
  for(const y of [-.45,-.15,.15,.45])box(head,-.1,y,0,1.02-(y+.45)*.4,.07,1.42-(y+.45)*.55,mats.blue).castShadow=false;
  box(head,.42,.02,0,.42,1.0,.78,mats.warmStone);
  box(head,.4,.75,0,.6,.35,.7,mats.gold);
  for(const z of [-.18,.18]){const e=box(head,.64,.18,z,.04,.09,.2,mats.egyptGlow);e.castShadow=false;}
  box(head,.64,-.12,0,.05,.22,.08,mats.darkStone);
  box(head,.55,-.7,0,.16,.42,.16,mats.blue);
  const uraeus=new THREE.Mesh(new THREE.ConeGeometry(.08,.3,6),mats.gold);uraeus.position.set(.72,.95,0);head.add(uraeus);
  g.rotation.y=.43;g.scale.setScalar(1.55);
 }
 // Distant pyramids as atmospheric monuments.
 for(let [x,z,s] of [[-22,-25,5],[20,-25,6]]){
   const pyr=new THREE.Mesh(new THREE.ConeGeometry(s,s*1.1,4),mats.sandstone);pyr.rotation.y=Math.PI/4;pyr.position.set(x,s*.55,z);ancient.add(pyr)
 }
 const west=new THREE.Group();root.add(west);
 // Sealed west courtyard: only its central door opens in the ancient echo.
 for(let [x,z,w,d] of [[-15.5,-11,11,.7],[-15.5,-3,11,.7],[-21,-7,.7,8],[-10,-10, .7,2],[-10,-4,.7,2]])box(west,x,1.15,z,w,2.3,d,mats.sandstone);
 const gateMat=mats.glass.clone();gateMat.transparent=true;gateMat.opacity=.6;gateMat.emissive=new THREE.Color('#1678ad');gateMat.emissiveIntensity=.5;
 const westGate=box(west,-10,1.45,-7, .8,2.9,4.1,gateMat);
 westGate.userData.dynamic=true;
 const westDoorFrame=box(west,-10,3.25,-7,1.5,.55,4.2,mats.gold);
 // East route: broken bridge and world-specific gate.
 // Raised above the plaza paving so the broken bridge reads clearly as open water.
 const canal=box(root,10,.06,-7,4,.1,6.2,mats.water);
 const moatEdges=[];for(let z of [-10.05,-3.95]){const w=box(root,13,.8,z,15,.9,.5,mats.darkStone);moatEdges.push(w)}
 box(root,20.3,1,-7,.5,1.5,6.7,mats.darkStone);
 const segments=[];for(let i=0;i<6;i++){
  let m=box(root,8.37+i*.65, .18-i*.04,-7,.68,.3,2.9,mats.warmStone);
  m.userData.baseX=8.37+i*.65;m.userData.offsetX=(i-2.5)*.12;m.userData.offsetZ=(i%2?1:-1)*.5;m.userData.drop=1.4+(i*1.37)%1*.55;m.userData.dynamic=true;segments.push(m)
 }
 const eastGate=box(root,15.4,1.37,-7,.75,2.75,5.8,mats.gold);
 eastGate.userData.dynamic=true;
 // Ancient shrine.
 const shrine=new THREE.Group();shrine.userData.dynamic=true;shrine.position.set(0,0,12.7);root.add(shrine);
 cylinder(shrine,0,.18,0,1.8,2.12,.37,mats.darkStone,8);
 cylinder(shrine,0,.5,0,1.22,1.48,.37,mats.sandstone,8);
 cylinder(shrine,0,1.04,0,.73,.91,.75,mats.gold,8);
 const shrineRing=new THREE.Mesh(new THREE.TorusGeometry(1.1,.065,8,48),mats.glow);shrineRing.rotation.x=Math.PI/2;shrineRing.position.y=.76;shrine.add(shrineRing);
 for(let i=0;i<6;i++){const a=i*Math.PI/3;const m=new THREE.Mesh(new THREE.OctahedronGeometry(.11,0),mats.egyptGlow);m.position.set(Math.cos(a)*1.02,1.05,Math.sin(a)*1.02);shrine.add(m)}
 // Nefertiti's enclosed court & present-day energy barrier.
 const court=new THREE.Group();root.add(court);
 for(let [x,z,w,d] of [[-4,-23,.8,9],[4,-23,.8,9],[0,-27,8,.8]])box(court,x,1.22,z,w,2.45,d,mats.sandstone);
 // Sanctuary floor and colonnade: a temple court that glows with ritual rings in the echo.
 box(court,0,.04,-23,7.2,.08,8,patchReality(makeMat('#cdb489'),{strength:.6,glyphs:1.4}));
 for(const [x,z] of [[-3.1,-19.9],[3.1,-19.9],[-3.1,-26.1],[3.1,-26.1]]){cylinder(court,x,1.5,z,.28,.34,3,mats.sandstone,10);cylinder(court,x,3.08,z,.45,.45,.18,mats.gold,10);}
 const finalBarrier=box(root,0,1.8,-19,7.1,3.5,.45,gateMat);
 finalBarrier.userData.dynamic=true;
 const queen=makeNefertiti(root,0,-24);
 queen.group.userData.dynamic=true;
 const queenCage=new THREE.Mesh(new THREE.TorusGeometry(1.4,.085,10,40),mats.egyptGlow);queenCage.userData.dynamic=true;queenCage.position.set(0,2,-24);queenCage.rotation.x=Math.PI/2;root.add(queenCage);
 const coinDefs=[{id:'A',x:-16.8,z:-7,label:'THE WEST SEAL'},{id:'B',x:18.4,z:-7,label:'THE EAST SEAL'},{id:'C',x:0,z:-13.5,label:'THE HIDDEN SEAL'}];
 const coins=coinDefs.map(c=>{
   const g=new THREE.Group();root.add(g);g.userData.dynamic=true;g.position.set(c.x,1.1,c.z);
   const halo=new THREE.Mesh(new THREE.TorusGeometry(.4,.075,10,30),mats.gold);halo.rotation.x=.25;g.add(halo);
   const core=new THREE.Mesh(new THREE.IcosahedronGeometry(.27,1),mats.glow);g.add(core);
   const beam=new THREE.Mesh(new THREE.CylinderGeometry(.06,.22,2.1,10,1,true),new THREE.MeshBasicMaterial({color:'#ffd082',transparent:true,opacity:.13,side:THREE.DoubleSide,depthWrite:false}));beam.position.y=-.2;g.add(beam);
   cylinder(root,c.x,.17,c.z,.72,.93,.3,mats.darkStone,7);return {...c,group:g,halo,core,picked:false}
 });
 const glyphRing=new THREE.Mesh(new THREE.TorusGeometry(1.9,.027,8,60),mats.egyptGlow);glyphRing.userData.dynamic=true;glyphRing.position.set(0,.15,12.7);glyphRing.rotation.x=Math.PI/2;root.add(glyphRing);
 const blockers = [
  ...agora.blockers,
  ...[[-15.5,-11,11,.7],[-15.5,-3,11,.7],[-21,-7,.7,8],[-10,-10,.7,2],[-10,-4,.7,2]].map(([x,z,w,d])=>({x,z,w,d})),
  {x:-10,z:-7,w:.8,d:3.95,when:'modern'},
  {x:15.4,z:-7,w:.75,d:5.8,when:'ancient'},
  {x:13,z:-10.05,w:15,d:.5},{x:13,z:-3.95,w:15,d:.5},{x:20.3,z:-7,w:.5,d:6.7},
  {x:-4,z:-23,w:.8,d:9},{x:4,z:-23,w:.8,d:9},{x:0,z:-27,w:8,d:.8},
  ...[[-3.1,-19.9],[3.1,-19.9],[-3.1,-26.1],[3.1,-26.1]].map(([x,z])=>({x,z,w:.6,d:.6})),
  {x:0,z:-19,w:7,d:.5,when:'modern'},
  {x:-11,z:9,w:9.4,d:5.8,when:'ancient'}
 ];
 const state={targetAncient:0,mix:0};
 function setAncient(enabled){state.targetAncient=enabled?1:0}
 function inAncient(){return state.targetAncient===1}
 function blocked(x,z,ancientState=inAncient()){
  if(x < -23.8 || x>23.8||z< -28.6||z>18.6)return true;
  const rad=.35;
  for(const b of blockers){if(b.when==='modern'&&ancientState)continue;if(b.when==='ancient'&&!ancientState)continue;
   if(Math.abs(x-b.x)<b.w/2+rad&&Math.abs(z-b.z)<b.d/2+rad)return true;
  }
  return false;
 }
 function inWater(x,z,ancientState=inAncient()){return x>8.12&&x<12.1&&z>-9.67&&z<-4.33&&!ancientState}
 function update(delta,elapsed,playerPosition){
  agora.update(playerPosition,delta);
  state.mix = THREE.MathUtils.damp(state.mix,state.targetAncient,3.2,delta);
  const k=state.mix;
  mats.brick.color.set('#6b4950').lerp(new THREE.Color('#92704f'),k);mats.glass.color.set('#5194a6').lerp(new THREE.Color('#31637b'),k);
  scene.background.copy(PALETTE.modernSky).lerp(PALETTE.ancientSky,k);
  scene.fog.color.copy(PALETTE.modernFog).lerp(PALETTE.ancientFog,k);
  // Monuments erupt from the ground exactly as the reversal wavefront reaches them.
  let anyRaised=false;
  for(const g of columns){const m=g.userData.m=THREE.MathUtils.damp(g.userData.m||0,reality.target(g.position.x,g.position.z),7,delta);
   const e=m<.001?0:1-Math.pow(1-m,3)+Math.sin(m*Math.PI)*.08;g.scale.y=Math.max(.001,e);g.position.y=-.4*(1-m);if(m>.01)anyRaised=true;}
  ancient.visible=anyRaised||k>.02;
  westGate.position.y=1.45-k*3.6;eastGate.position.y=1.37-(1-k)*3.6;
  finalBarrier.position.y=1.8-k*4.8;
  for(const m of segments){const a=1-k;m.position.x=m.userData.baseX+a*m.userData.offsetX;m.position.z=-7+a*m.userData.offsetZ;m.position.y=.18-a*m.userData.drop;m.rotation.z=(Math.sin(m.userData.baseX*8)*.25)*a;m.rotation.x=a*.18;}
  const showHidden=state.targetAncient===1 && k>.45;
  for(const c of coins){if(c.picked){c.pickT=(c.pickT??1)+delta;const t=c.pickT/.9;c.group.visible=t<1;if(t<1){c.group.position.y=1.12+t*t*2.6;c.group.scale.setScalar(1+t*.9-(t>.7?(t-.7)*3.2:0));c.halo.rotation.z+=delta*14;}continue;}c.group.visible=c.id==='C'?showHidden:true;c.group.position.y=1.12+.16*Math.sin(elapsed*2.5+c.x);c.halo.rotation.z=elapsed*.65;}
  shrineRing.rotation.z=elapsed*.19;glyphRing.rotation.z=-elapsed*.2;
  queen.halo.rotation.z=elapsed*.23;queenCage.visible=false;
 }
 return {root,scene,coins,shrine,queen,agora,blockers,setAncient,inAncient,blocked,inWater,update,state};
}
