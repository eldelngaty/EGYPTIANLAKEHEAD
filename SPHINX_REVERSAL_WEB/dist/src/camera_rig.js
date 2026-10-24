import * as THREE from '../vendor/three.module.min.js';
// Swept camera sphere against authored 3D collision boxes. Pure slab math avoids
// per-frame triangle raycasts and stays consistent with the actual doorway openings.
export function segmentEntry(a,b,box,radius=.22){
 let lo=0,hi=1;
 for(const axis of ['x','y','z']){const min=box.min[axis]-radius,max=box.max[axis]+radius,d=b[axis]-a[axis];if(Math.abs(d)<1e-9){if(a[axis]<min||a[axis]>max)return null;continue;}let near=(min-a[axis])/d,far=(max-a[axis])/d;if(near>far)[near,far]=[far,near];lo=Math.max(lo,near);hi=Math.min(hi,far);if(lo>hi)return null;}
 return hi>=0&&lo<=1?Math.max(0,lo):null;
}
export function clipCamera(anchor,wanted,boxes,radius=.22){let t=1;for(const box of boxes){const entry=segmentEntry(anchor,wanted,box,radius);if(entry!==null)t=Math.min(t,entry);}const distance=anchor.distanceTo(wanted),safe=t<1?Math.max(0,t-(distance>.001?.07/distance:0)):1;return {position:anchor.clone().lerp(wanted,safe),fraction:safe};}
export function cameraVolumes(world){const boxes=[];
 for(const b of world.blockers){if(b.when==='modern'&&world.inAncient()||b.when==='ancient'&&!world.inAncient())continue;const y=b.y??((b.h??(b.low?1:3))*.5),h=b.h??(b.low?1:3);boxes.push({min:{x:b.x-b.w*.5,y:y-h*.5,z:b.z-b.d*.5},max:{x:b.x+b.w*.5,y:y+h*.5,z:b.z+b.d*.5}});}
 boxes.push(...world.agora.cameraBounds);
 // Opening glass leaves are tracked in their real, animated positions.
 for(const {leaf} of world.agora.doors){leaf.updateWorldMatrix(true,true);const b=new THREE.Box3().setFromObject(leaf);boxes.push(b);}
 return boxes;
}
export class FollowCamera{
 constructor(){this.anchor=new THREE.Vector3();this.boxes=[];this.obstructed=false;this.clearance=0;this.automaticOrbit=0;}
 update(camera,anchor,yaw,pitch,distance,boxes,dt){
  this.anchor.copy(anchor);this.boxes=boxes;const orbit=(angle,tilt=pitch)=>anchor.clone().add(new THREE.Vector3(Math.sin(angle)*Math.cos(tilt),Math.sin(tilt),Math.cos(angle)*Math.cos(tilt)).multiplyScalar(distance));
  let choice=clipCamera(anchor,orbit(yaw),boxes),used=0;this.obstructed=choice.fraction<.98;
  // Tight wall corners: find room beside/behind the player before allowing a
  // camera distance that intersects the guardian's torso or head.
  if(choice.position.distanceTo(anchor)<1.9){
   for(const offset of [.55,-.55,1.1,-1.1,Math.PI/2,-Math.PI/2,Math.PI]){const candidate=clipCamera(anchor,orbit(yaw+offset),boxes);if(candidate.position.distanceTo(anchor)>choice.position.distanceTo(anchor)+.1){choice=candidate;used=offset;}if(choice.position.distanceTo(anchor)>=2.3)break;}
  }
  if(choice.position.distanceTo(anchor)<1.5){const up=clipCamera(anchor,anchor.clone().add(new THREE.Vector3(0,2.4,0)),boxes);if(up.position.distanceTo(anchor)>choice.position.distanceTo(anchor)){choice=up;used=Math.PI;}}
  this.automaticOrbit=used;
  const smoothed=camera.position.clone().lerp(choice.position,1-Math.exp(-dt*(this.obstructed?18:8)));
  const constrained=clipCamera(anchor,smoothed,boxes);
  camera.position.copy(constrained.position.distanceTo(anchor)<1.5&&choice.position.distanceTo(anchor)>=1.5?choice.position:constrained.position);
  camera.lookAt(anchor);this.clearance=camera.position.distanceTo(anchor);
 }
 enforce(camera){const safe=clipCamera(this.anchor,camera.position,this.boxes);camera.position.copy(safe.position);camera.lookAt(this.anchor);this.clearance=camera.position.distanceTo(this.anchor);}
}
