import * as THREE from '../vendor/three.module.min.js';
// Source face conventions verified against the official tour tiles and Godot
// reference mapping. Explicit quads avoid mirrored/swapped WebGL cubemap faces.
export async function loadTourReference(faces){
 const scene=new THREE.Scene(),L=4;
 const points={
  front:[[-L,L,-L],[L,L,-L],[L,-L,-L],[-L,-L,-L]],
  right:[[L,L,-L],[L,L,L],[L,-L,L],[L,-L,-L]],
  back:[[L,L,L],[-L,L,L],[-L,-L,L],[L,-L,L]],
  left:[[-L,L,L],[-L,L,-L],[-L,-L,-L],[-L,-L,L]],
  top:[[-L,L,L],[L,L,L],[L,L,-L],[-L,L,-L]],
  bottom:[[-L,-L,-L],[L,-L,-L],[L,-L,L],[-L,-L,L]]};
 const order=['right','left','top','bottom','back','front'],loader=new THREE.TextureLoader();
 await Promise.all(order.map(async(name,i)=>{const texture=await loader.loadAsync(faces[i]);texture.colorSpace=THREE.SRGBColorSpace;texture.anisotropy=4;const geometry=new THREE.BufferGeometry();geometry.setAttribute('position',new THREE.Float32BufferAttribute(points[name].flat(),3));geometry.setAttribute('uv',new THREE.Float32BufferAttribute([0,1,1,1,1,0,0,0],2));geometry.setIndex([0,1,2,0,2,3]);const material=new THREE.MeshBasicMaterial({map:texture,side:THREE.DoubleSide,toneMapped:false});const mesh=new THREE.Mesh(geometry,material);mesh.name='Verified tour face / '+name;scene.add(mesh);}));
 return scene;
}
