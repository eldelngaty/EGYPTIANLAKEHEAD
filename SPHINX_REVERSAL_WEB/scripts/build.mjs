// Offline build: source ESM + the original game's locally bundled Three.js.
// No remote package registry, asset CDN, iframe or server-side runtime is needed.
import {cp,mkdir,rm,writeFile} from 'node:fs/promises';
import {resolve} from 'node:path';
const out=resolve('dist');
await rm(out,{recursive:true,force:true});
await mkdir(out,{recursive:true});
await Promise.all([
 cp('index.html',resolve(out,'index.html')),
 cp('src',resolve(out,'src'),{recursive:true}),
 cp('vendor',resolve(out,'vendor'),{recursive:true}),
 cp('THREE_LICENSE.txt',resolve(out,'THREE_LICENSE.txt'))
]);
await writeFile(resolve(out,'BUILD_INFO.json'),JSON.stringify({build:'Offline local ESM / Three.js',madeAt:new Date().toISOString(),reference:'Official Lakehead Agora Circle screenshot; no panorama embedded'},null,2));
console.log('Built complete, locally runnable dist/ without external network dependencies.');
