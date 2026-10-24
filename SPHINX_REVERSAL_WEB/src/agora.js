import * as THREE from '../vendor/three.module.min.js';
import {box,cylinder} from './world.js';
import {patchReality,glyphTexture,reality} from './reality.js';

// Architectural study drawn from the supplied Agora Circle screenshot.
// The entrance is placed at z=-9.55; the original seal/shrine coordinates stay intact.
// The atrium behind it is an openly acknowledged playable approximation, NOT a scanned plan.
const material=(color,extras={})=>new THREE.MeshStandardMaterial({color,roughness:.79,...extras});
// Facade palette sampled by eye from the reference photo: warm tan precast, red-brown brick.
const cream=patchReality(material('#c2ad9b'),{strength:.85}), fascia=patchReality(material('#a88e7e'),{strength:.85}), ribs=patchReality(material('#8a7464'),{strength:.85});
const brick=patchReality(material('#7a4a40'),{strength:.6}), blueFrame=material('#2a3236',{metalness:.26,roughness:.42});
const parapet=patchReality(material('#b49f8d'),{strength:.85}), bronze=material('#3a2e27',{metalness:.5,roughness:.45});
const plaque=material('#4a3a2c',{metalness:.35,roughness:.5});
function skyReflection(dark=false){
 const c=document.createElement('canvas');c.width=512;c.height=256;const g=c.getContext('2d');
 const grad=g.createLinearGradient(0,0,0,256);
 if(dark){grad.addColorStop(0,'#3d5866');grad.addColorStop(1,'#141d22');}else{grad.addColorStop(0,'#cfe4f5');grad.addColorStop(.5,'#6f9fcb');grad.addColorStop(1,'#2b4d74');}
 g.fillStyle=grad;g.fillRect(0,0,512,256);
 // Reflected spruce silhouettes and soft diagonal sheen.
 g.fillStyle=dark?'#0c1418':'#243e42';
 for(const [x,h] of [[40,150],[120,90],[300,130],[430,170],[470,110]]){
  g.strokeStyle=dark?'#121d20':'#30454a';g.lineWidth=3;g.beginPath();g.moveTo(x,256);g.lineTo(x,256-h);g.stroke();
  for(let k=0;k<24;k++){const a=k*2.399,r=8+(k*13)%33,cx=x+Math.cos(a)*r,cy=256-h+Math.sin(a)*r*1.4+15;g.beginPath();g.ellipse(cx,cy,13+(k%4)*3,9+(k%3)*4,a,0,Math.PI*2);g.fill();}
 }
 g.globalAlpha=.16;g.fillStyle='#ffffff';for(let x=-200;x<600;x+=170){g.beginPath();g.moveTo(x,0);g.lineTo(x+60,0);g.lineTo(x-40,256);g.lineTo(x-100,256);g.fill();}
 const t=new THREE.CanvasTexture(c);t.colorSpace=THREE.SRGBColorSpace;t.wrapS=THREE.RepeatWrapping;t.repeat.set(3,1);return t;
}
const skyTex=skyReflection();
const skyGlass=material('#ffffff',{map:skyTex,emissiveMap:skyTex,emissive:'#8c8c8c',metalness:.1,roughness:.15});
const lowerGlass=material('#ffffff',{map:skyReflection(true),metalness:.3,roughness:.2,transparent:true,opacity:.85});
const glassDark=material('#263b42',{metalness:.22,roughness:.28,transparent:true,opacity:.35,depthWrite:false,side:THREE.DoubleSide});
const pale=material('#d0c5b7'), grout=material('#7f786f');
const benchGreen=material('#3f7a4c'), benchDark=material('#2c3a32');
const interiorWall=patchReality(material('#c7b4a4'),{strength:.7}), interiorTrim=material('#85756c');
const doorGlass=material('#a3d4d6',{transparent:true,opacity:.27,metalness:.18,roughness:.16,depthWrite:false,side:THREE.DoubleSide});
const warmBulb=material('#ffffd1',{emissive:'#ffe0a8',emissiveIntensity:1.15});
const timber=material('#7b4a35',{roughness:.9});

function textPanel(text,w,h,color='#9d7e43',size=84){
 const c=document.createElement('canvas');c.width=1024;c.height=256;
 const ctx=c.getContext('2d');ctx.clearRect(0,0,c.width,c.height);
 ctx.fillStyle=color;ctx.font=`600 ${size}px Georgia`;ctx.textAlign='center';ctx.textBaseline='middle';ctx.fillText(text,512,128,950);
 const t=new THREE.CanvasTexture(c);t.colorSpace=THREE.SRGBColorSpace;
 return new THREE.Mesh(new THREE.PlaneGeometry(w,h),new THREE.MeshBasicMaterial({map:t,transparent:true,depthWrite:false,side:THREE.DoubleSide}));
}
function pavedTexture(){
 const canvas=document.createElement('canvas');canvas.width=512;canvas.height=512;
 const c=canvas.getContext('2d');c.fillStyle='#8f8079';c.fillRect(0,0,512,512);
 const tones=['#b9a49a','#b39e95','#bfaaa0','#ad9a92','#c2aea3','#b6a197','#a99890'];
 for(let row=0;row<16;row++){const off=row%2?32:0;
  for(let col=-1;col<8;col++){const x=col*64+off,y=row*32,v=(row*7+col*11+13)%7;
   c.fillStyle=tones[v];c.fillRect(x+1.5,y+1.5,61,29);
   c.fillStyle='rgba(255,255,255,.05)';c.fillRect(x+3,y+3,57,2);
   for(let k=0;k<14;k++){c.fillStyle=`rgba(${k%2?255:40},${k%2?255:30},${k%2?255:30},.06)`;c.fillRect(x+2+((k*37+row*13)%58),y+2+((k*23+col*7)%26),2,2);}
  }
 }
 const t=new THREE.CanvasTexture(canvas);t.colorSpace=THREE.SRGBColorSpace;t.wrapS=t.wrapT=THREE.RepeatWrapping;t.repeat.set(9,9);t.anisotropy=8;return t;
}
function makeBench(parent,x,z,facing=Math.PI){
 const b=new THREE.Group();b.position.set(x,0,z);b.rotation.y=facing;parent.add(b);
 for(const zz of [-.16,.1,.36])box(b,0,.62,zz,1.85,.12,.13,benchGreen);
 for(let y=.93;y<1.35;y+=.18)box(b,0,y,.48,1.85,.11,.09,benchGreen);
 for(const xx of [-.77,.77]){
  box(b,xx,.34,.06,.1,.63,.65,benchDark);
  box(b,xx,1,.45,.12,.8,.1,benchDark);
 }
 return b;
}
function makePoplar(root,x,z){
 cylinder(root,x,.9,z,.1,.15,1.8,material('#5b4636'),7);
 const f=new THREE.Mesh(new THREE.SphereGeometry(1,10,8),material('#3f6a34'));f.scale.set(.85,3.6,.85);f.position.set(x,4.4,z);f.castShadow=true;root.add(f);
}
function makePlanter(root,x,z){
 const p=new THREE.Group();p.position.set(x,0,z);p.rotation.y=-.35;root.add(p);
 for(let i=0;i<10;i++)box(p,-2.2+i*.49,.42,0,.44,.84,2.4,timber);
 box(p,0,.86,0,4.7,.08,2.2,material('#4f6b33'));
 for(const [dx,dz] of [[-1.2,.3],[0,-.4],[1.3,.2]]){const f=new THREE.Mesh(new THREE.IcosahedronGeometry(.42,0),material('#b54a52'));f.position.set(dx,1.05,dz);p.add(f);}
}
function makeTree(root,x,z,tall=false){
 cylinder(root,x,1.2,z,.12,.19,2.4,material('#6b5140'),8);
 const foliage=new THREE.Mesh(new THREE.ConeGeometry(tall?.78:1.16,tall?5.1:3.9,9),material(tall?'#426b3a':'#638353'));
 foliage.position.set(x,tall?4.05:3.45,z);foliage.castShadow=true;root.add(foliage);
}
// Return both collision rectangles and movable doors. The doorway remains free at
// ALL times; the automatic leaves animate before the Pharaoh crosses the threshold.
export function createAgoraCampus(root){
 const group=new THREE.Group();group.name='AgoraCampus / reference-based exterior';root.add(group);
 const atrium=new THREE.Group();atrium.name='Agora atrium - approximate walkable interior';root.add(atrium);
 const blockers=[];
 const solid=(parent,x,y,z,w,h,d,mat,blocking=true)=>{
  const m=box(parent,x,y,z,w,h,d,mat);
  if(blocking)blockers.push({x,z,w,d});return m;
 };
 // Wide slab-paved foreground (rectangular running-bond pavers, as photographed).
 const tileMat=patchReality(new THREE.MeshStandardMaterial({map:pavedTexture(),color:'#ffffff',roughness:.93}),{strength:.75,glyphs:1});
 box(group,0,.045,3.1,28,.10,28,tileMat);
 // Lawn strip along the facade base, benches facing the plaza (reference composition).
 const lawn=patchReality(material('#5d7f3e'),{strength:.9});
 for(const [x,w] of [[-9.6,8.6],[8.6,6.4]])box(group,x,.1,-8.75,w,.12,1.25,lawn);
 // Main visual silhouette: beige ribbed low fascia + high reflective glass ribbon.
 // Only the actual lower walls are collidable; the fascia/windows float above walk height.
 const frontZ=-9.55,backZ=-18.15;
 for(const x of [-5.25,5.25]){
  solid(group,x,1.48,frontZ,7.5,2.96,.45,blueFrame);
  box(group,x,1.58,frontZ+.245,7.1,2.5,.035,lowerGlass);
  // Storefront mullions and slim concrete piers carrying the canopy.
  for(let i=-3;i<=3;i++)box(group,x+i*1.02,1.58,frontZ+.29,.06,2.55,.07,bronze);
  for(const px of [x-3.6,x+3.6])box(group,px,1.6,frontZ+.42,.34,3.2,.34,cream);
  box(group,x,2.9,frontZ+.3,7.1,.1,.1,bronze);
 }
 box(group,-8.2,1.2,frontZ+.28,1.1,2.3,.06,material('#2f5fa8',{roughness:.5})); // blue service door, left of the glazing
 // Recessed two-leaf main entrance. A 3m wide center aisle is always passable.
 for(const x of [-1.64,1.64])box(group,x,1.6,frontZ+.24,.13,3.15,.20,cream);
 box(group,0,3.06,frontZ,3.1,.29,.45,cream);
 box(group,0,.065,frontZ+.48,3.7,.04,1.0,grout);
 // Modernist fascia extends unbroken above doors; a band of vertical concrete ribs.
 box(group,0,3.72,frontZ+.13,21,1.29,1.08,fascia);
 const ribGeo=new THREE.BoxGeometry(.06,1.16,.05),ribMesh=new THREE.InstancedMesh(ribGeo,ribs,60);let ri=0;
 for(let x=-10.30;x<=10.3&&ri<60;x+=.35){ribMesh.setMatrixAt(ri++,new THREE.Matrix4().makeTranslation(x,3.74,frontZ+.685));}
 ribMesh.count=ri;ribMesh.castShadow=true;group.add(ribMesh);
 // Bronze plaque with raised lettering, slightly right of centre as in the photograph.
 box(group,1.6,3.74,frontZ+.71,3.9,.98,.05,plaque);
 const sign=textPanel('Lakehead',3.6,.82,'#e9cc8e',122);sign.position.set(1.6,3.8,frontZ+.75);group.add(sign);
 const subtitle=textPanel('U N I V E R S I T Y',2.2,.2,'#e9cc8e',62);subtitle.position.set(1.6,3.39,frontZ+.75);group.add(subtitle);
 // Ancient echo: the same plaque becomes a royal cartouche.
 const cartouche=new THREE.Mesh(new THREE.PlaneGeometry(3.7,.9),new THREE.MeshBasicMaterial({map:glyphTexture(1024,256,{cols:7,rows:1,seed:1,back:'#2b1708'}),transparent:true,opacity:0,depthWrite:false}));
 cartouche.position.set(1.6,3.74,frontZ+.77);group.add(cartouche);
 // Upper glass ribbon: tall panes reflecting the sky, dark bronze mullions.
 box(group,0,6.0,frontZ-.30,20.7,3.15,.36,blueFrame);
 box(group,0,6.0,frontZ-.05,20.45,2.78,.10,skyGlass);
 for(let x=-9.98;x<=10.0;x+=1.3)box(group,x,6.02,frontZ+.08,.1,3.01,.16,bronze);
 box(group,0,4.55,frontZ+.02,20.7,.14,.3,bronze);
 // Ancient echo: a gold hieroglyph frieze ignites across the glass ribbon.
 const frieze=new THREE.Mesh(new THREE.PlaneGeometry(20.4,2.7),new THREE.MeshBasicMaterial({map:glyphTexture(2048,272,{cols:22,rows:2,seed:4}),transparent:true,opacity:0,depthWrite:false,blending:THREE.AdditiveBlending}));
 frieze.position.set(0,6.0,frontZ+.18);group.add(frieze);
 // Segmented precast parapet along the roofline.
 box(group,0,7.79,frontZ-.15,21.25,.42,1.1,cream);
 for(let x=-10.2;x<=10.25;x+=1.3)box(group,x,7.86,frontZ+.42,1.18,.5,.08,parapet);
 // Side wings anchor the facade: left dark-red brick block, right beige walkway wing.
 box(group,-10.6,2.52,-11.0,3.4,5.1,3.6,brick);
 box(group,-10.6,5.0,-11.0,3.6,.42,4.0,cream);
 box(group,10.65,3.6,-11.2,3.0,7.3,4.4,cream);
 for(const z of [-10.0,-11.2,-12.4]){
  box(group,10.65,4.9,z,3.06,1.1,.13,glassDark);
  box(group,10.65,5.48,z,3.06,.12,.15,fascia);
 }
 // A glazed lobby viewed through the entrance. No solid roof spanning the
 // center of the atrium: the third-person camera can see the player indoors.
 box(atrium,0,.052,-13.92,18.0,.105,8.78,material('#8b8176'));
 const insideTiles=patchReality(new THREE.MeshStandardMaterial({map:pavedTexture(),color:'#efe6d8',roughness:.7}),{strength:.6,glyphs:.6});
 box(atrium,0,.115,-13.92,17.6,.02,8.3,insideTiles);
 for(const x of [-8.9,8.9])solid(atrium,x,2.5,-13.92,.45,5,8.7,interiorWall);
 // Rear wall into existing Nefertiti path: central opening aligned with the doors.
 for(const x of [-5.17,5.17])solid(atrium,x,1.52,backZ,7.15,3.04,.36,interiorWall);
 box(atrium,0,3.26,backZ,17.95,.47,.56,cream);
 box(atrium,0,5.2,backZ,17.95,3.1,.4,brick);
 // A shallow, translucent skylight and edge beams communicate an indoor atrium,
 // while staying transparent enough for the third-person gameplay camera.
 const skylight=material('#96bad0',{transparent:true,opacity:.16,roughness:.16,depthWrite:false,side:THREE.DoubleSide});
 box(atrium,0,7.26,-13.9,17.3,.06,8.25,skylight);
 for(const x of [-8.45,8.45])box(atrium,x,7.18,-13.9,.23,.24,8.6,interiorTrim);
 for(const z of [-10.2,-13.9,-17.75])box(atrium,0,7.2,z,17,.26,.20,interiorTrim);
 // Vertical arcade, tile skirting, brown cladding, long overhead beams and fixtures.
 for(const x of [-6.9,6.9]){
  for(const z of [-11.8,-15.8]){
   solid(atrium,x,1.7,z,.48,3.4,.48,cream);
   box(atrium,x,3.6,z,.75,.34,.75,fascia);
  }
  box(atrium,x,3.55,-13.92,.16,.30,8.05,interiorTrim);
  for(const z of [-12,-14,-16])box(atrium,x>0?8.5:-8.5,2,z,.075,3.2,.07,brick,false);
 }
 for(const z of [-11.6,-14.4,-17.2]){
  box(atrium,0,4.5,z,18,.26,.33,interiorTrim);
  for(const x of [-4.1,0,4.1]){
   box(atrium,x,4.29,z,.83,.07,.32,warmBulb);
  }
 }
 // Alcoves and information boards: visual only, out of the traversal corridor.
 for(const side of [-1,1]){
  const x=side*8.55;
  for(const z of [-11.65,-14.05,-16.45]){
   box(atrium,x,2.15,z,.08,1.8,1.4,glassDark);
   box(atrium,x-side*.09,3.16,z,.13,.10,1.47,cream);
  }
  // Tall information kiosk parallel to the walls; does not block central path.
  box(atrium,side*6.1,.83,-16.5,.42,1.55,1.2,brick);
  const notice=textPanel(side<0?'STUDENT SERVICES':'WELCOME TO AGORA',2.25,.55,'#efe3ce',61);
  notice.position.set(side*5.8,2.88,-15.25);notice.rotation.y=side*Math.PI/2;atrium.add(notice);
 }
 // Door hardware and actual independent sliding glass leaves.
 const doors=[];
 for(const side of [-1,1]){
  const leaf=box(group,side*.78,1.51,frontZ+.35,1.43,2.87,.09,doorGlass);
  box(leaf,0,0,0,.025,1,.18,blueFrame); // vertical stainless handle (leaf-relative)
  leaf.userData.dynamic=true;doors.push({leaf,side,baseX:side*.78});
 }
 // Exterior landscape seen in the reference: columnar poplars by the brick wing,
 // a broad deciduous tree, slatted timber planter and green park benches.
 for(const [x,z] of [[-11.8,-7.4],[-10.2,-7.6],[-13.3,-7.0]])makePoplar(group,x,z);
 makeTree(group,-14.7,-4.1,false);makeTree(group,12.6,-13.6,false);
 makePlanter(group,-11.2,2.2);
 for(const [x,z] of [[-9.0,-7.8],[-5.2,-7.8],[4.4,-7.8]])makeBench(group,x,z);
 // Left/right campus wing connections; these are visual silhouettes, not blocking the puzzle routes.
 box(group,-14.7,2.1,-11.5,4.8,4.2,3.3,brick);
 box(group,14.2,2.6,-12.3,4.0,5.2,3.3,cream);
 // Thunder Bay boreal surroundings: one instanced spruce ring + outer ground, so the
 // intro fly-over never shows the world's edge. Two draw calls in total.
 const outer=new THREE.Mesh(new THREE.CircleGeometry(140,48),patchReality(material('#4c6638',{roughness:1}),{strength:.95}));
 outer.rotation.x=-Math.PI/2;outer.position.y=-.64;outer.receiveShadow=false;root.add(outer);
 const spruceGeo=new THREE.ConeGeometry(1.6,7,7);spruceGeo.translate(0,3.5,0);
 const spruces=new THREE.InstancedMesh(spruceGeo,patchReality(material('#2f4d2c'),{strength:.4}),180);
 const m4=new THREE.Matrix4(),q=new THREE.Quaternion(),sc=new THREE.Vector3(),ps=new THREE.Vector3();let n=0;
 for(let i=0;i<180;i++){const a=i*2.399+Math.sin(i)*.3,r=33+((i*37)%29)+(i%3)*4,x=Math.cos(a)*r,z=Math.sin(a)*r-4;
  if(Math.abs(x)<25&&z>-30&&z<20)continue;const k=.8+((i*13)%10)/10;sc.set(k,k*(1+(i%4)*.15),k);ps.set(x,-.6,z);m4.compose(ps,q,sc);spruces.setMatrixAt(n++,m4);}
 spruces.count=n;root.add(spruces);
 // Interior identity: navy-and-gold Lakehead banners (text only, no logo) that become
 // Egyptian glyph standards in the echo, plus student lounge tables with collision.
 const bannerTex=(lines)=>{const c=document.createElement('canvas');c.width=128;c.height=512;const g=c.getContext('2d');g.fillStyle='#14305a';g.fillRect(0,0,128,512);g.fillStyle='#d9b45f';g.fillRect(0,0,128,14);g.fillRect(0,498,128,14);g.font='bold 34px Georgia';g.textAlign='center';lines.forEach((l,i)=>g.fillText(l,64,90+i*48));const t=new THREE.CanvasTexture(c);t.colorSpace=THREE.SRGBColorSpace;return t;};
 const modernBanner=new THREE.MeshBasicMaterial({map:bannerTex(['L','A','K','E','H','E','A','D']),transparent:true,side:THREE.DoubleSide});
 const ancientBanner=new THREE.MeshBasicMaterial({map:glyphTexture(128,512,{cols:1,rows:5,seed:2,back:'#5a1d12'}),transparent:true,opacity:0,side:THREE.DoubleSide,depthWrite:false});
 const banners=[];
 for(const side of [-1,1])for(const z of [-12.6,-15.2]){
  const b1=new THREE.Mesh(new THREE.PlaneGeometry(.9,3.4),modernBanner);b1.position.set(side*8.62,3.6,z);b1.rotation.y=-side*Math.PI/2;atrium.add(b1);
  const b2=new THREE.Mesh(new THREE.PlaneGeometry(.9,3.4),ancientBanner);b2.position.set(side*8.6,3.6,z);b2.rotation.y=-side*Math.PI/2;atrium.add(b2);banners.push(b1);
 }
 const tableTop=material('#d8d2c4'),chair=material('#b4462f');
 for(const [x,z] of [[-3.4,-11.4],[3.4,-11.4],[-3.6,-17.0],[3.6,-17.0]]){
  cylinder(atrium,x,.38,z,.08,.12,.76,interiorTrim,8);cylinder(atrium,x,.78,z,.55,.55,.06,tableTop,16);
  for(const a of [0,Math.PI/2,Math.PI,3*Math.PI/2])box(atrium,x+Math.cos(a)*.85,.42,z+Math.sin(a)*.85,.42,.08,.42,chair),box(atrium,x+Math.cos(a)*1.05,.7,z+Math.sin(a)*1.05,Math.abs(Math.cos(a))>.5?.06:.42,.55,Math.abs(Math.cos(a))>.5?.42:.06,chair);
  blockers.push({x,z,w:1.5,d:1.5,low:true}); // low: ignored by camera occlusion
 }
 // Atrium light: warm interior glow so the entrance reads as an occupied building.
 const lobbyLight=new THREE.PointLight('#ffd9a6',14,16,1.6);lobbyLight.position.set(0,4,-14);atrium.add(lobbyLight);
 const signInterior=textPanel('AGORA',3.0,.7,'#f5e1b3',100);signInterior.position.set(0,3.35,-17.93);atrium.add(signInterior);
 let echo=0;
 return {
  group,atrium,blockers,doors,
  update(playerPosition,dt){
   // Facade transformation follows the reversal wavefront, not a global fade.
   echo=THREE.MathUtils.damp(echo,reality.target(0,frontZ),6,Math.max(dt||0,.016));
   frieze.material.opacity=echo*.95;ancientBanner.opacity=echo;modernBanner.opacity=1-echo*.9;cartouche.material.opacity=echo;sign.material.opacity=subtitle.material.opacity=1-echo;
   skyGlass.emissive.setRGB(.55+echo*.4,.55+echo*.2,.55-echo*.25);lobbyLight.color.setRGB(1,.85-echo*.2,.65-echo*.35);
   if(!playerPosition)return;
   const near=Math.abs(playerPosition.x)<3.55&&Math.abs(playerPosition.z-frontZ)<3.0;
   for(const {leaf,side,baseX} of doors){
    const dest=baseX+(near?side*1.47:0);
    // Door group is animated independently, never merged by optimize.js.
    leaf.position.x=THREE.MathUtils.damp(leaf.position.x,dest,8,Math.max(dt,.016));
   }
  },
  isInside(x,z){return Math.abs(x)<8.9&&z<frontZ&&z>backZ;}
 };
}
