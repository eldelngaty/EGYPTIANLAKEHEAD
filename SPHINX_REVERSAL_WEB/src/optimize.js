import * as THREE from '../vendor/three.module.min.js';
// Batch opaque, static siblings only. Animated parents, doors, artifacts and
// transparent effects keep their identities and transforms. Collision data is separate.
export function batchStaticMeshes(root){
 let removed=0;
 function visit(parent){
  if(parent.userData.dynamic)return;
  for(const child of [...parent.children])if(!child.isMesh)visit(child);
  const buckets=new Map();
  for(const m of parent.children){if(!m.isMesh||m.isInstancedMesh||!m.visible||m.userData.dynamic||m.userData.baseColor||Array.isArray(m.material)||m.material.transparent||m.geometry.morphAttributes.position||!m.geometry.attributes.normal||!m.geometry.attributes.uv)continue;
   const key=m.material.uuid+':'+Number(m.castShadow)+':'+Number(m.receiveShadow);if(!buckets.has(key))buckets.set(key,[]);buckets.get(key).push(m);
  }
  for(const nodes of buckets.values()){
   if(nodes.length<3)continue;
   const pieces=nodes.map(m=>{m.updateMatrix();const g=m.geometry.index?m.geometry.toNonIndexed():m.geometry.clone();g.applyMatrix4(m.matrix);return g;});
   const g=new THREE.BufferGeometry();
   for(const key of ['position','normal','uv']){const itemSize=pieces[0].attributes[key].itemSize,array=new Float32Array(pieces.reduce((n,p)=>n+p.attributes[key].array.length,0));let offset=0;for(const p of pieces){array.set(p.attributes[key].array,offset);offset+=p.attributes[key].array.length;}g.setAttribute(key,new THREE.BufferAttribute(array,itemSize));}
   g.computeBoundingBox();g.computeBoundingSphere();const combined=new THREE.Mesh(g,nodes[0].material);combined.name='Static campus batch / '+nodes.length+' meshes';combined.castShadow=nodes[0].castShadow;combined.receiveShadow=nodes[0].receiveShadow;parent.add(combined);for(const n of nodes)parent.remove(n);for(const p of pieces)p.dispose();removed+=nodes.length-1;
  }
 }
 visit(root);root.userData.batchedDrawCalls=removed;return root;
}
