import * as THREE from '../vendor/three.module.min.js';
import {box,cylinder,planeLabel} from './world.js';

const materialCache=new Map();
const mat=(color,extra={})=>{const key=color+JSON.stringify(extra);if(!materialCache.has(key))materialCache.set(key,new THREE.MeshStandardMaterial({color,roughness:.75,...extra}));return materialCache.get(key);};
// All artwork is generated locally: no asset downloads, fonts, or texture requests.
export function dressCampus(world){
 const {root}=world;
 const navy=mat('#102e50'), gold=mat('#e7b655',{metalness:.65,roughness:.3});
 const dark=mat('#152837'), stone=mat('#a7b5bd'), brick=mat('#5d4550');
 const light=mat('#70eced',{emissive:'#27b4cf',emissiveIntensity:1.3});
 const warm=mat('#ffce76',{emissive:'#ffa546',emissiveIntensity:1.8});
 const ancient=new THREE.Group();root.add(ancient);
 const modern=new THREE.Group();root.add(modern);
 const rising=[], ripples=[], flames=[],foliage=[];
 function label(text,x,y,z,w=4,rotation=0,parent=root){const l=planeLabel(text,'#f2d294','#102539',w,w*.145);l.position.set(x,y,z);l.rotation.y=rotation;parent.add(l);return l;}
 function floorRing(x,z,r,color,width=.035,parent=root){const g=new THREE.Mesh(new THREE.RingGeometry(r-width,r,96),new THREE.MeshBasicMaterial({color,side:THREE.DoubleSide,transparent:true,opacity:.8,depthWrite:false}));g.rotation.x=-Math.PI/2;g.position.set(x,.085,z);parent.add(g);return g;}
 // Agora Circle itself is modeled in agora.js from the actual supplied screenshot.
 // Ancient echo ornaments below remain, without overwriting its architecture.
 // Ancient obelisks flank each chapter. Gold/cyan inlay remains readable in shadow.
 for(const [x,z] of [[-7.4,-2.8],[7.4,-2.8],[-6,-15.6],[6,-15.6]]){
  const g=new THREE.Group();g.position.set(x,0,z);ancient.add(g);g.userData.dynamic=true;rising.push(g);
  box(g,0,.25,0,1.5,.5,1.5,dark);box(g,0,2.2,0,.8,3.6,.8,navy);
  const top=new THREE.Mesh(new THREE.ConeGeometry(.57,.85,4),gold);top.rotation.y=Math.PI/4;top.position.y=4.4;g.add(top);
  for(let y=1;y<3.9;y+=.55){const sig=planeLabel(y<2?'◈':'✦','#7ff9f2','#123453',.43,.43);sig.position.set(0,y,.407);g.add(sig);}
  cylinder(g,0,.6,0,.64,.64,.09,gold,8);
 }
 // Each puzzle gets an environmental inscription, not just an abstract HUD objective.
 label('I   •   THE WESTERN ARCHIVE',-15.5,2.9,-2.55,8);
 label('II   •   BRIDGE OF OPPOSITES',12.3,1.5,-3.6,8);
 label('III   •   THE UNSEEN',0,.15,-11.1,3.4).rotation.x=-Math.PI/2;
 label('SHRINE OF RETURN   •   A  B  C',0,.2,15.4,5).rotation.x=-Math.PI/2;
 // Glyphs surrounding the hidden seal are a constellation only the ancient echo completes.
 for(let i=0;i<10;i++){
  const a=i*Math.PI/5;floorRing(Math.sin(a)*1.8,-13.5+Math.cos(a)*1.8,.13,'#55f5e1',.05,ancient);
 }
 // Layered bridge rails guide the player to a safe landing before changing reality.
 for(const z of [-8.6,-5.4])for(let x=8.3;x<12.2;x+=.7){const g=new THREE.Group();g.position.set(x,0,z);ancient.add(g);g.userData.dynamic=true;rising.push(g);box(g,0,.6,0,.12,1.1,.12,navy);box(g,0,1.15,0,.68,.1,.12,gold);}
 floorRing(13.4,-7,.7,'#79ece4',.08);
 // Final sanctuary: a luminous arch, the queen's cage and an anchor in the present.
 for(const x of [-3.2,3.2]){
  box(root,x,2.4,-19,1,4.8,1.2,navy);box(root,x,4.8,-19,1.4,.28,1.5,gold);
 }
 box(root,0,5.25,-19,7.6,.65,1.5,navy);label('THE QUEEN BETWEEN WORLDS',0,5.27,-18.22,6.4,0);
 const anchor=new THREE.Group();anchor.userData.dynamic=true;anchor.position.set(2,0,-22);root.add(anchor);
 cylinder(anchor,0,.42,0,.48,.67,.8,dark,8);const anchorCore=new THREE.Mesh(new THREE.OctahedronGeometry(.36,0),light);anchorCore.position.y=1.15;anchor.add(anchorCore);
 const cage=new THREE.Group();cage.userData.dynamic=true;cage.position.set(0,0,-24);root.add(cage);
 for(let i=0;i<12;i++){const a=i*Math.PI/6;const bar=box(cage,Math.cos(a)*1.35,1.6,Math.sin(a)*1.35,.025,3.2,.025,light);bar.rotation.y=a;}
 for(let y of [.15,3.2]){const ring=new THREE.Mesh(new THREE.TorusGeometry(1.35,.025,6,64),light);ring.rotation.x=Math.PI/2;ring.position.y=y;cage.add(ring);}
 // Braziers and glow sprites: no post-processing dependency required.
 const glowCanvas=document.createElement('canvas');glowCanvas.width=glowCanvas.height=64;
 const ctx=glowCanvas.getContext('2d'),gradient=ctx.createRadialGradient(32,32,0,32,32,32);gradient.addColorStop(0,'#ffffff');gradient.addColorStop(.18,'#fff0b0aa');gradient.addColorStop(1,'#ff8d0000');ctx.fillStyle=gradient;ctx.fillRect(0,0,64,64);
 const glowTexture=new THREE.CanvasTexture(glowCanvas);
 for(const [x,z] of [[-2,11],[2,11],[-2.6,-21],[2.6,-21],[-8.9,-5],[-8.9,-9],[14,-5.1]]){
  cylinder(ancient,x,.65,z,.16,.35,1.3,dark,8);cylinder(ancient,x,1.38,z,.4,.22,.2,gold,8);
  const flame=new THREE.Mesh(new THREE.IcosahedronGeometry(.19,1),warm);flame.position.set(x,1.65,z);ancient.add(flame);flame.userData.dynamic=true;flames.push(flame);
  const sprite=new THREE.Sprite(new THREE.SpriteMaterial({map:glowTexture,color:'#ffcb74',transparent:true,opacity:.75,depthWrite:false,blending:THREE.AdditiveBlending}));sprite.scale.set(2,2,1);sprite.position.set(x,1.65,z);ancient.add(sprite);
 }
 // The eye above the campus gateway is drawn as vector strokes, so it never
 // depends on OS support for Egyptian Unicode characters.
 const eyeCanvas=document.createElement('canvas');eyeCanvas.width=512;eyeCanvas.height=320;
 const eg=eyeCanvas.getContext('2d');eg.strokeStyle='#79fff1';eg.fillStyle='#b9fff2';eg.lineWidth=8;eg.lineCap='round';eg.shadowColor='#4af2ff';eg.shadowBlur=20;
 eg.beginPath();eg.moveTo(55,130);eg.quadraticCurveTo(253,0,457,130);eg.quadraticCurveTo(256,265,55,130);eg.stroke();
 eg.beginPath();eg.arc(256,130,47,0,Math.PI*2);eg.fill();eg.beginPath();eg.moveTo(256,180);eg.lineTo(256,285);eg.moveTo(255,216);eg.lineTo(119,292);eg.moveTo(323,177);eg.quadraticCurveTo(451,195,425,276);eg.stroke();
 const eyeTexture=new THREE.CanvasTexture(eyeCanvas);
 const eye=new THREE.Mesh(new THREE.PlaneGeometry(2.4,1.5),new THREE.MeshBasicMaterial({map:eyeTexture,transparent:true,side:THREE.DoubleSide,depthWrite:false,blending:THREE.AdditiveBlending}));
 eye.position.set(0,6.2,-1.2);eye.rotation.x=-.35;eye.userData.dynamic=true;ancient.add(eye);
 const eyeHalo=new THREE.Mesh(new THREE.TorusGeometry(1.65,.025,6,96),light);eyeHalo.position.copy(eye.position);eyeHalo.rotation.x=-.35;eyeHalo.userData.dynamic=true;ancient.add(eyeHalo);
 for(let i=0;i<12;i++){const a=i*Math.PI/6;const shard=new THREE.Mesh(new THREE.OctahedronGeometry(.07),gold);shard.position.set(Math.cos(a)*1.85,6.2+Math.sin(a)*1.85,-1.2);ancient.add(shard);}
 // A travelling floor wave makes every reversal legible across the entire courtyard.
 const wave=new THREE.Mesh(new THREE.RingGeometry(.94,1,128),new THREE.MeshBasicMaterial({color:'#82e9ff',transparent:true,opacity:0,side:THREE.DoubleSide,depthWrite:false,blending:THREE.AdditiveBlending}));wave.rotation.x=-Math.PI/2;wave.position.y=.13;root.add(wave);
 const count=260,positions=new Float32Array(count*3),seeds=[];
 for(let i=0;i<count;i++){seeds.push({x:Math.sin(i*32.3)*23,z:Math.cos(i*17.7)*25-3,y:(i*1.73)%6});}
 const geo=new THREE.BufferGeometry();geo.setAttribute('position',new THREE.BufferAttribute(positions,3));
 const particles=new THREE.Points(geo,new THREE.PointsMaterial({color:'#ffce7b',size:.11,map:glowTexture,transparent:true,opacity:.7,depthWrite:false,blending:THREE.AdditiveBlending}));root.add(particles);
 let pulse=10,victory=0;
 function reverse(x,z){pulse=0;wave.position.set(x,.14,z);wave.material.color.set(world.inAncient()?'#ffcf76':'#71dbff');}
 function update(dt,t,k,options={}){
  eye.position.y=6.2+Math.sin(t*1.3)*.09;eyeHalo.rotation.z=t*.1;eye.scale.setScalar(.9+k*.1);
  pulse+=dt;const radius=1+pulse*27;wave.scale.setScalar(radius);wave.material.opacity=Math.max(0,1-pulse/1.3)*.75;
  ancient.visible=k>.01;
  for(const g of rising){g.scale.y=Math.max(.001,k);g.position.y=-.3*(1-k);}
  modern.position.y=-.15*k;
  for(const tr of foliage){tr.rotation.z=Math.sin(t*.7+tr.position.x)*.025;tr.traverse(o=>{if(o.userData.baseColor)o.material.color.copy(o.userData.baseColor).lerp(new THREE.Color('#b98d5a'),k*.5);});}
  for(const f of flames){f.scale.y=1+.3*Math.sin(t*9+f.position.x);f.position.y=1.65+.05*Math.sin(t*7+f.position.z);}
  for(let i=0;i<count;i++){const s=seeds[i];positions[i*3]=s.x+Math.sin(t*.2+i)*.4;positions[i*3+1]=(s.y+t*(.13+k*.23))%6;positions[i*3+2]=s.z+Math.cos(t*.2+i)*.3;}geo.attributes.position.needsUpdate=true;
  particles.material.opacity=.2+k*.55;particles.material.color.set(k>.5?'#ffd082':'#86dfff');
  cage.visible=!options.rescued;cage.scale.y=THREE.MathUtils.damp(cage.scale.y,options.anchorReleased?.01:1,5,dt);
  anchorCore.rotation.y=t;anchorCore.material=options.anchorReleased?gold:light;
  if(options.rescued){victory+=dt;world.queen.group.position.y=Math.min(1.7,victory*.3);world.queen.halo.scale.setScalar(1+Math.sin(victory*2)*.1);}
  else{victory=0;world.queen.group.position.y=0;world.queen.halo.scale.setScalar(1);}
  ripples.forEach(r=>{r.material.opacity=.4+.2*Math.sin(t*2)});
 }
 for(const node of [eye,eyeHalo,anchorCore,...flames])node.userData.dynamic=true;
 return {update,reverse,anchor,cage};
}
