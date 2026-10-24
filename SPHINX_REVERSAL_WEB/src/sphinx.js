import * as THREE from '../vendor/three.module.min.js';
// Original procedural quadruped: shared-vertex organic meshes + articulated two-bone legs.
const mat=(color,options={})=>new THREE.MeshStandardMaterial({color,roughness:.78,...options});
function mesh(parent,geo,material,x=0,y=0,z=0){const m=new THREE.Mesh(geo,material);m.position.set(x,y,z);m.castShadow=true;m.receiveShadow=true;parent.add(m);return m;}
function ellipsoid(parent,p,s,material){const m=mesh(parent,new THREE.SphereGeometry(1,16,10),material,...p);m.scale.set(...s);return m;}
function block(parent,p,s,material){return mesh(parent,new THREE.BoxGeometry(...s),material,...p);}
function link(node,a,b,len){node.position.copy(a).add(b).multiplyScalar(.5);node.quaternion.setFromUnitVectors(new THREE.Vector3(0,1,0),b.clone().sub(a).normalize());node.scale.y=a.distanceTo(b)/len;}
function loftZ(rings,segments=20){const pos=[],index=[],uv=[];rings.forEach(([z,rx,ry,cy],j)=>{for(let i=0;i<=segments;i++){const a=i/segments*Math.PI*2;pos.push(Math.cos(a)*rx,cy+Math.sin(a)*ry,z);uv.push(i/segments,j/(rings.length-1));}});for(let j=0;j<rings.length-1;j++)for(let i=0;i<segments;i++){const a=j*(segments+1)+i,b=a+segments+1;index.push(a,a+1,b,b,a+1,b+1);}const g=new THREE.BufferGeometry();g.setAttribute('position',new THREE.Float32BufferAttribute(pos,3));g.setAttribute('uv',new THREE.Float32BufferAttribute(uv,2));g.setIndex(index);g.computeVertexNormals();return g;}
export function makeGuardian(root){
 const group=new THREE.Group();group.name='Sphinx / original animated lion guardian';root.add(group);
 const texCanvas=document.createElement('canvas');texCanvas.width=texCanvas.height=128;const ctx=texCanvas.getContext('2d');ctx.fillStyle='#d8bd94';ctx.fillRect(0,0,128,128);for(let i=0;i<2200;i++){ctx.fillStyle=`rgba(${i%2?255:60},${i%2?242:45},${i%2?216:30},.08)`;ctx.fillRect((i*71)%128,(i*37+Math.floor(i/128)*11)%128,1,1);}const grain=new THREE.CanvasTexture(texCanvas);grain.colorSpace=THREE.SRGBColorSpace;
 const stone=mat('#c7a378',{map:grain,roughness:.88}),gold=mat('#e5bb60',{metalness:.62,roughness:.34}),blue=mat('#124573',{metalness:.2,roughness:.48}),dark=mat('#182a35');
 const stripeCanvas=document.createElement('canvas');stripeCanvas.width=64;stripeCanvas.height=256;const c=stripeCanvas.getContext('2d');c.fillStyle='#174e83';c.fillRect(0,0,64,256);for(let i=0;i<14;i++){c.fillStyle='#d6b15f';c.fillRect(0,i*19,64,5);}const stripes=new THREE.CanvasTexture(stripeCanvas);stripes.colorSpace=THREE.SRGBColorSpace;stripes.anisotropy=4;const nemes=mat('#ffffff',{map:stripes,metalness:.22,roughness:.5});
 const body=new THREE.Group();group.add(body);
 mesh(body,loftZ([[-1.02,.06,.08,1.05],[-.88,.34,.36,1.04],[-.53,.47,.46,1.06],[.12,.40,.34,1.02],[.57,.37,.32,.98],[.85,.41,.36,.98],[1.04,.04,.05,.99]]),stone);
 for(const side of [-1,1]){ellipsoid(body,[side*.32,1.02,-.60],[.23,.38,.35],stone);ellipsoid(body,[side*.32,.95,.68],[.26,.36,.36],stone);}
 const head=new THREE.Group();head.position.set(0,1.13,-.81);body.add(head);
 ellipsoid(head,[0,.18,0],[.28,.34,.29],stone);
 // Carved jaw and cheek silhouette. Front is local -Z, matching the original controller.
 const face=mesh(head,new THREE.CylinderGeometry(.28,.19,.55,10),stone,0,.56,-.055);face.scale.z=1.02;
 ellipsoid(head,[0,.79,.015],[.30,.24,.28],stone);
 ellipsoid(head,[0,.88,.04],[.44,.22,.36],nemes);
 for(const side of [-1,1]){
  const shape=new THREE.Shape();shape.moveTo(side*.28,.90);shape.lineTo(side*.48,.86);shape.lineTo(side*.58,-.10);shape.lineTo(side*.34,-.12);shape.closePath();
  const lappet=mesh(head,new THREE.ExtrudeGeometry(shape,{depth:.27,bevelEnabled:true,bevelThickness:.035,bevelSize:.025,bevelSegments:1,steps:1}),blue,0,0,-.20);
  const geo=new THREE.BufferGeometry();geo.setAttribute('position',new THREE.Float32BufferAttribute([side*.28,.90,-.239,side*.48,.86,-.239,side*.58,-.10,-.239,side*.34,-.12,-.239],3));geo.setAttribute('uv',new THREE.Float32BufferAttribute([0,1,1,1,1,0,0,0],2));geo.setIndex([0,2,1,0,3,2]);geo.computeVertexNormals();const striped=nemes.clone();striped.side=THREE.DoubleSide;mesh(head,geo,striped);
  ellipsoid(head,[side*.12,.65,-.318],[.085,.026,.018],dark);
  ellipsoid(head,[side*.12,.651,-.337],[.022,.018,.008],gold);
  const brow=block(head,[side*.12,.705,-.295],[.20,.028,.035],dark);brow.rotation.z=side*.12;
  ellipsoid(head,[side*.275,.51,.01],[.06,.09,.055],stone);
 }
 const noseGeo=new THREE.BufferGeometry();noseGeo.setAttribute('position',new THREE.Float32BufferAttribute([-.047,.67,-.30,.047,.67,-.30,0,.51,-.42,-.047,.48,-.31,.047,.48,-.31,0,.51,-.42],3));noseGeo.computeVertexNormals();const noseMat=stone.clone();noseMat.side=THREE.DoubleSide;mesh(head,noseGeo,noseMat);
 block(head,[0,.411,-.275],[.14,.018,.025],mat('#78543b'));
 mesh(head,new THREE.CylinderGeometry(.05,.035,.22,8),blue,0,.24,-.26).rotation.x=-.2;
 block(head,[0,.83,-.315],[.64,.047,.045],gold);
 mesh(head,new THREE.CylinderGeometry(.026,.033,.19,8),gold,0,1.01,-.30);ellipsoid(head,[0,1.12,-.30],[.056,.075,.036],gold);
 for(let i=0;i<15;i++){const a=(i-7)*.19,x=Math.sin(a)*.44,z=-.76-Math.cos(a)*.40,y=1.22-Math.abs(Math.sin(a))*.12;const plate=block(body,[x,y,z],[.085,.22,.05],gold);plate.rotation.z=-a*.4;block(body,[x,y,z-.033],[.046,.13,.016],blue);}
 const legs=[];
 for(const side of [-1,1])for(const front of [true,false]){
  const pivot=new THREE.Group(),origin=new THREE.Vector3(side*.34,.87,front?-.61:.65);pivot.position.copy(origin);group.add(pivot);
  const upper=mesh(pivot,new THREE.CylinderGeometry(.15,.105,.46,12),stone),lower=mesh(pivot,new THREE.CylinderGeometry(.105,.067,.46,12),stone);
  const paw=ellipsoid(group,[origin.x,.11,origin.z-.06],[.16,.11,.24],stone);
  for(let i=-1;i<=1;i++)ellipsoid(paw,[i*.42,-.02,-.62],[.24,.45,.33],stone);
  legs.push({pivot,upper,lower,paw,origin,phase:(front===(side>0)?0:Math.PI),front});
 }
 const tail=new THREE.Group();tail.position.set(0,1.1,.95);body.add(tail);const curve=new THREE.CatmullRomCurve3([new THREE.Vector3(),new THREE.Vector3(.14,-.20,.38),new THREE.Vector3(.34,-.27,.70),new THREE.Vector3(.48,-.10,.86),new THREE.Vector3(.40,.10,.91)]);mesh(tail,new THREE.TubeGeometry(curve,18,.045,7,false),stone);ellipsoid(tail,[.40,.1,.91],[.085,.10,.13],mat('#826140'));
 const ring=mesh(group,new THREE.RingGeometry(.48,.51,40),new THREE.MeshBasicMaterial({color:'#d9bc73',transparent:true,opacity:.17,side:THREE.DoubleSide}),0,.018,0);ring.rotation.x=-Math.PI/2;
 // Preserve the old small light attachment contract; no floating staff on a quadruped.
 const orb=new THREE.Object3D();head.add(orb);
 let phase=0,blend=0;
 function animate(dt,speed,time,turn=0){blend=THREE.MathUtils.damp(blend,Math.min(1,speed/2.4),14,dt);phase+=speed*dt*4;
  for(const leg of legs){const cycle=THREE.MathUtils.euclideanModulo(phase+leg.phase,Math.PI*2)/(Math.PI*2),t=cycle*2;const step=(cycle<.5?THREE.MathUtils.lerp(.393,-.393,t*t*(3-2*t)):THREE.MathUtils.lerp(-.393,.393,t-1))*blend,lift=cycle<.5?Math.sin(cycle*Math.PI*2)*.16*blend:0;
   const end=new THREE.Vector3(0,-.76+lift,step-.04),perp=new THREE.Vector3(0,-end.z,end.y).normalize(),bend=Math.sqrt(Math.max(0,.46*.46-end.lengthSq()/4));const knee=end.clone().multiplyScalar(.5).addScaledVector(perp,bend*(leg.front?-1:1));link(leg.upper,new THREE.Vector3(),knee,.46);link(leg.lower,knee,end,.46);leg.paw.position.copy(leg.origin).add(end);
  }
  body.position.y=Math.sin(time*1.9)*.007+Math.sin(phase*2)*.012*blend;body.rotation.z=THREE.MathUtils.clamp(turn,-1,1)*blend*.06;head.rotation.y=Math.sin(time*.7)*.035*(1-blend);tail.rotation.y=Math.sin(time*1.8+phase*.1)*.14;
 }
 animate(0,0,0);
 return {group,body,head,legs,tail,ring,orb,animate,model:'Original articulated quadruped Sphinx'};
}
