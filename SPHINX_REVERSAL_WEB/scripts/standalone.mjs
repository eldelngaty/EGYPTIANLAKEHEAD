// Optional packaging tool only. The resulting HTML needs no Node, server or Internet.
import {readFile,writeFile} from 'node:fs/promises';
import {createRequire} from 'node:module';
const require=createRequire(import.meta.url);
let esbuild;try{esbuild=require(process.env.ESBUILD_MODULE||'esbuild');}catch{throw Error('Standalone packaging requires esbuild (available through npm install). Normal npm run build remains dependency-free.');}
const result=await esbuild.build({entryPoints:['src/main.js'],bundle:true,format:'iife',minify:true,write:false,target:['es2020'],legalComments:'eof'});
const script=result.outputFiles[0].text.replace(/<\/script/gi,'<\\/script');
const css=await readFile('src/style.css','utf8');
let html=await readFile('index.html','utf8');
html=html.replace('<link rel="stylesheet" href="./src/style.css">',()=>'<style>'+css+'</style>');

html=html.replace('<script type="module" src="./src/main.js"></script>',()=>'<script>'+script+'</script>');
await writeFile('PLAY_SPHINX.html',html);
await writeFile('PLAY_PHARAOH.html',html);
console.log('Created PLAY_SPHINX.html: double-click to play offline without a server.');
