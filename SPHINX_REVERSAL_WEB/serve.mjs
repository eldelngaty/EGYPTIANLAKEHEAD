// Dependency-free local launcher for the prebuilt game. Node.js 20.19+.
import {createServer} from 'node:http';
import {readFile,stat} from 'node:fs/promises';
import {resolve,extname,dirname,sep} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawn} from 'node:child_process';
const base=dirname(fileURLToPath(import.meta.url));
const root=process.argv.includes('--source')?base:resolve(base,'dist');
const requestedPort=Number(process.env.PORT)||4173;
const firstPort=Number.isInteger(requestedPort)&&requestedPort>0&&requestedPort<65536?requestedPort:4173;
let port=firstPort;
const types={'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.mjs':'text/javascript; charset=utf-8','.css':'text/css; charset=utf-8','.svg':'image/svg+xml','.png':'image/png','.json':'application/json'};
const server=createServer(async(req,res)=>{
 try{const url=new URL(req.url,'http://localhost');const pathname=decodeURIComponent(url.pathname);const file=resolve(root,'.'+(pathname==='/'?'/index.html':pathname));if(!file.startsWith(root+sep)){res.writeHead(403);res.end('Forbidden');return;}const data=await readFile(file);res.writeHead(200,{'Content-Type':types[extname(file)]||'application/octet-stream','Cache-Control':'no-cache'});res.end(data);}catch{res.writeHead(404);res.end('Not found');}
});
server.on('error',e=>{
 if(e.code==='EADDRINUSE'&&port<firstPort+20){port++;console.warn(`Port ${port-1} is already in use. Trying http://127.0.0.1:${port}/ instead.`);server.listen(port,'127.0.0.1');return;}
 console.error(e.code==='EADDRINUSE'?`No free port was found between ${firstPort} and ${firstPort+20}. Set PORT to a free port and try again.`:e.message);process.exitCode=1;
});
try{await stat(resolve(root,'index.html'));}catch{console.error('Missing index.html. Run npm run build first if serving dist.');process.exit(1);}
server.listen(port,'127.0.0.1',()=>{const url=`http://127.0.0.1:${port}/`;console.log(`\nSPHINX REVERSAL — Rescue at Lakehead\n\nOpen ${url}\nKeep this terminal open. Press Ctrl+C to stop.\n`);if(process.argv.includes('--open')){const cmd=process.platform==='win32'?['cmd.exe',['/c','start','',url]]:process.platform==='darwin'?['open',[url]]:['xdg-open',[url]];const child=spawn(cmd[0],cmd[1],{stdio:'ignore'});child.on('error',()=>{});child.unref();}});
