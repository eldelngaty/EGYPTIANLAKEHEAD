import {readFile,writeFile} from 'node:fs/promises';
import {createRequire} from 'node:module';
const require=createRequire(import.meta.url),esbuild=require(process.env.ESBUILD_MODULE||'esbuild');
const r=await esbuild.build({entryPoints:['src/hero_preview.js'],bundle:true,format:'iife',write:false,minify:true,legalComments:'eof'});
const template=await readFile('portrait.template.html','utf8');
const html=template.replace('<script type="module" src="./src/hero_preview.js"></script>',()=>'<script>'+r.outputFiles[0].text.replace(/<\/script/gi,'<\\/script')+'</script>');
await writeFile('PHARAOH_PORTRAIT.html',html);
console.log('Built actual-character offline portrait renderer.');
