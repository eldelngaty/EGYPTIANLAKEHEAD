import * as THREE from '../vendor/three.module.min.js';
// Original armored human Pharaoh. This is not the inaccessible Sketchfab asset.
const material=(color,opts={})=>new THREE.MeshStandardMaterial({color,roughness:.48,...opts});
function mesh(parent,geometry,mat,pos=[0,0,0]){const m=new THREE.Mesh(geometry,mat);m.position.set(...pos);m.castShadow=true;m.receiveShadow=true;parent.add(m);return m;}
function orb(parent,pos,size,mat){const m=mesh(parent,new THREE.SphereGeometry(1,20,14),mat,pos);m.scale.set(...size);return m;}
function box(parent,pos,size,mat){const g=new THREE.BoxGeometry(...size);return mesh(parent,g,mat,pos);}
function tube(parent,pos,top,bottom,height,mat,n=16){return mesh(parent,new THREE.CylinderGeometry(top,bottom,height,n),mat,pos);}
function loft(parent,rings,mat,n=20){const v=[],uv=[],idx=[];for(let j=0;j<rings.length;j++){const [y,rx,rz]=rings[j];for(let i=0;i<=n;i++){const a=i/n*Math.PI*2;v.push(Math.sin(a)*rx,y,Math.cos(a)*rz);uv.push(i/n,j/(rings.length-1));}}for(let j=0;j<rings.length-1;j++)for(let i=0;i<n;i++){const a=j*(n+1)+i,b=a+n+1;idx.push(a,a+1,b,b,a+1,b+1);}const g=new THREE.BufferGeometry();g.setAttribute('position',new THREE.Float32BufferAttribute(v,3));g.setAttribute('uv',new THREE.Float32BufferAttribute(uv,2));g.setIndex(idx);g.computeVertexNormals();return mesh(parent,g,mat);}
function connect(m,a,b,len){m.position.copy(a).add(b).multiplyScalar(.5);m.quaternion.setFromUnitVectors(new THREE.Vector3(0,1,0),b.clone().sub(a).normalize());m.scale.y=a.distanceTo(b)/len;}
export function makePharaoh(root){
 const group=new THREE.Group();group.name='PHARAOH / original royal protector';root.add(group);
 const gold=material('#d4a64d',{metalness:.82,roughness:.3}),edge=material('#f1d291',{metalness:.65,roughness:.27}),lapis=material('#164f85',{metalness:.4,roughness:.32}),blue=material('#06294d',{metalness:.3,roughness:.42}),skin=material('#b57d57',{roughness:.8}),linen=material('#e4dcc3',{roughness:.9}),black=material('#142029',{roughness:.8}),turquoise=material('#39aab8',{metalness:.35,roughness:.3});
 const body=new THREE.Group();group.add(body);
 // Tailored chest silhouette and layered ceremonial armor, rather than a cylinder torso.
 loft(body,[[.95,.23,.16],[1.11,.27,.18],[1.43,.38,.22],[1.64,.34,.19],[1.67,.20,.14]],blue);
 loft(body,[[1.13,.225,.18],[1.34,.31,.205],[1.57,.33,.205],[1.60,.23,.15]],gold);
 for(const side of [-1,1]){const panel=orb(body,[side*.16,1.43,-.17],[.15,.18,.07],lapis);panel.rotation.z=side*.12;orb(body,[side*.14,1.14,-.15],[.13,.13,.055],blue);}
 // Raised winged scarab and small turquoise inlays on the breastplate.
 orb(body,[0,1.42,-.249],[.075,.10,.027],turquoise);
 for(const side of [-1,1])for(let i=0;i<5;i++){const wing=box(body,[side*(.09+i*.034),1.45-i*.019,-.235],[.028,.10-i*.009,.025],edge);wing.rotation.z=-side*.5;}
 for(let i=0;i<3;i++){tube(body,[0,1.12+i*.08,0],.253+i*.012,.253+i*.012,.036,edge);}
 // Pleated linen and segmented blue/gold apron.
 loft(body,[[.70,.36,.26],[.99,.27,.19],[1.08,.25,.18]],linen);
 for(let i=0;i<11;i++){const a=(i-5)*.17;const strip=box(body,[Math.sin(a)*.31,.86,-Math.cos(a)*.245],[.013,.27,.018],gold);strip.rotation.z=-a*.2;}
 box(body,[0,.91,-.268],[.25,.36,.045],lapis);box(body,[0,.91,-.295],[.031,.32,.012],edge);
 for(const side of [-1,1]){box(body,[side*.135,.91,-.283],[.026,.35,.025],gold);orb(body,[side*.27,1.055,0],[.10,.09,.20],gold);}
 tube(body,[0,1.08,0],.29,.29,.085,gold);orb(body,[0,1.08,-.207],[.086,.08,.035],turquoise);
 // Broad layered Egyptian usekh collar.
 for(let i=0;i<15;i++){const a=(i-7)*.17;const x=Math.sin(a)*.35,z=-Math.cos(a)*.22;const plate=box(body,[x,1.59-Math.abs(Math.sin(a))*.06,z-.016],[.055,.16,.045],edge);plate.rotation.z=-a*.3;box(body,[x,1.59-Math.abs(Math.sin(a))*.06,z-.043],[.032,.105,.018],turquoise);}
 tube(body,[0,1.70,0],.12,.135,.23,skin);
 const head=new THREE.Group();head.position.set(0,1.77,0);body.add(head);
 loft(head,[[-.07,.105,.10],[.01,.15,.145],[.19,.18,.16],[.35,.16,.14],[.40,.11,.11]],skin,20);
 for(const side of [-1,1]){orb(head,[side*.075,.20,-.151],[.052,.016,.011],black);orb(head,[side*.075,.20,-.163],[.014,.012,.006],edge);const brow=box(head,[side*.077,.247,-.147],[.115,.018,.02],black);brow.rotation.z=side*.12;orb(head,[side*.177,.13,.002],[.035,.059,.025],skin);}
 const nose=new THREE.BufferGeometry();nose.setAttribute('position',new THREE.Float32BufferAttribute([-.025,.22,-.145,.025,.22,-.145,0,.12,-.225,-.03,.102,-.157,.03,.102,-.157,0,.12,-.225],3));nose.computeVertexNormals();const nm=skin.clone();nm.side=THREE.DoubleSide;mesh(head,nose,nm);
 box(head,[0,.055,-.141],[.084,.012,.016],material('#6d4535'));tube(head,[0,-.055,-.105],.025,.037,.16,lapis,10).rotation.x=-.15;
 // Volumetric striped nemes: face remains unobstructed between two flared lappets.
 const c=document.createElement('canvas');c.width=64;c.height=256;const ctx=c.getContext('2d');ctx.fillStyle='#123f73';ctx.fillRect(0,0,64,256);for(let i=0;i<18;i++){ctx.fillStyle='#d5b064';ctx.fillRect(0,i*15,64,4);}const texture=new THREE.CanvasTexture(c);texture.colorSpace=THREE.SRGBColorSpace;texture.anisotropy=8;const stripe=material('#ffffff',{map:texture,metalness:.4,roughness:.37});
 orb(head,[0,.35,.045],[.27,.20,.245],stripe);
 for(const side of [-1,1]){const shape=new THREE.Shape();shape.moveTo(side*.15,.41);shape.lineTo(side*.31,.35);shape.lineTo(side*.36,-.22);shape.lineTo(side*.21,-.24);shape.closePath();mesh(head,new THREE.ExtrudeGeometry(shape,{depth:.24,bevelEnabled:true,bevelSize:.018,bevelThickness:.018,bevelSegments:2}),lapis,[0,0,-.08]);
  for(let i=0;i<12;i++){const y=-.20+i*.047,x=side*(.277-i*.003);const band=box(head,[x,y,-.109],[.14,.012,.014],edge);band.rotation.z=side*.08;}
 }
 box(head,[0,.315,-.188],[.37,.037,.031],gold);tube(head,[0,.412,-.176],.018,.022,.16,gold,10);orb(head,[0,.503,-.18],[.039,.049,.023],edge);
 const arms=[];
 for(const side of [-1,1]){const arm=new THREE.Group();arm.position.set(side*.39,1.51,0);body.add(arm);orb(arm,[0,.015,0],[.16,.15,.18],gold);orb(arm,[side*.025,.055,-.025],[.14,.095,.16],lapis);tube(arm,[0,-.17,0],.08,.065,.29,blue);tube(arm,[0,-.31,0],.075,.075,.075,edge);tube(arm,[0,-.43,-.015],.076,.060,.24,gold);orb(arm,[0,-.59,-.025],[.066,.09,.055],skin);for(let i=0;i<3;i++)box(arm,[(i-1)*.027,-.64,-.066],[.018,.075,.018],skin);arms.push(arm);
  if(side===1){const staff=new THREE.Group();staff.position.set(.06,-.33,-.10);arm.add(staff);tube(staff,[0,-.10,0],.021,.028,1.72,gold,12);const ankh=mesh(staff,new THREE.TorusGeometry(.105,.019,8,32),edge,[0,.83,0]);box(staff,[0,.665,0],[.30,.032,.032],edge);tube(staff,[0,.57,0],.021,.021,.30,gold);orb(staff,[0,.83,0],[.053,.064,.017],turquoise);}
 }
 const cape=new THREE.Group();cape.position.set(0,1.58,.16);body.add(cape);
 const capeShape=new THREE.Shape();capeShape.moveTo(-.22,0);capeShape.lineTo(.22,0);capeShape.lineTo(.34,-1.02);capeShape.quadraticCurveTo(0,-1.13,-.34,-1.02);capeShape.closePath();const capeMat=blue.clone();capeMat.side=THREE.DoubleSide;mesh(cape,new THREE.ShapeGeometry(capeShape,12),capeMat);for(const side of [-1,1]){const seam=box(cape,[side*.275,-.53,.007],[.022,1.01,.018],gold);seam.rotation.z=side*.115;}box(cape,[0,-1.03,.008],[.65,.028,.025],gold);
 const legs=[];
 for(const side of [-1,1]){const origin=new THREE.Vector3(side*.145,.94,0),pivot=new THREE.Group();pivot.position.copy(origin);group.add(pivot);const upper=tube(pivot,[0,0,0],.105,.085,.48,blue),lower=tube(pivot,[0,0,0],.085,.067,.48,gold);const knee=orb(pivot,[0,-.43,0],[.095,.095,.08],lapis);const foot=orb(group,[origin.x,.07,-.075],[.105,.07,.19],blue);box(foot,[0,.40,-.20],[1.45,.16,.40],gold);legs.push({origin,pivot,upper,lower,knee,foot,phase:side<0?0:Math.PI});}
 const ring=mesh(group,new THREE.RingGeometry(.39,.415,48),new THREE.MeshBasicMaterial({color:'#e8c57e',transparent:true,opacity:.14,side:THREE.DoubleSide}),[0,.015,0]);ring.rotation.x=-Math.PI/2;const orbAnchor=new THREE.Object3D();head.add(orbAnchor);
 let stride=0,blend=0;
 function animate(dt,speed,time,turn=0,air={}){blend=THREE.MathUtils.damp(blend,Math.min(1,speed/2.4),14,dt);stride+=speed*dt*4.6;
  for(const leg of legs){const phase=THREE.MathUtils.euclideanModulo(stride+leg.phase,Math.PI*2)/(Math.PI*2),t=phase*2,travel=(phase<.5?THREE.MathUtils.lerp(.34,-.34,t*t*(3-2*t)):THREE.MathUtils.lerp(-.34,.34,t-1))*blend,lift=phase<.5?Math.sin(phase*Math.PI*2)*.13*blend:0,end=new THREE.Vector3(0,-.87+lift+(air.height>.06?Math.min(.18,air.height*.22):0),air.height>.06?-.08:travel-.04),distance=Math.min(.959,end.length()),bend=Math.sqrt(Math.max(0,.48*.48-distance*distance*.25)),normal=new THREE.Vector3(0,-end.z,end.y).normalize(),joint=end.clone().multiplyScalar(.5).addScaledVector(normal,bend);connect(leg.upper,new THREE.Vector3(),joint,.48);connect(leg.lower,joint,end,.48);leg.knee.position.copy(joint);leg.foot.position.copy(leg.origin).add(end);}
  body.position.y=Math.sin(time*1.8)*.005+Math.sin(stride*2)*.012*blend-(air.landing||0)*.045;body.rotation.z=THREE.MathUtils.clamp(turn,-1,1)*blend*.045;head.rotation.y=Math.sin(time*.65)*.03*(1-blend);arms[0].rotation.x=Math.sin(stride)*.28*blend;arms[1].rotation.x=-Math.sin(stride)*.06*blend;cape.rotation.x=-.10-blend*.22+Math.sin(time*3+stride*.3)*.035;
 }
 animate(0,0,0);return {group,body,head,legs,arms,cape,ring,orb:orbAnchor,animate,model:'Original armored human Pharaoh',heroType:'pharaoh'};
}
