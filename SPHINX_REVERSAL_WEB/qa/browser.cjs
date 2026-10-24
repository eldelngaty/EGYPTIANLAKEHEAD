// Use a local Playwright install (playwright or playwright-core), or one named by PLAYWRIGHT_MODULE.
// QA_PORT selects the served port (default 4173). CHROME_PATH overrides the browser executable.
const fs=require('node:fs'),path=require('node:path');
let api;
for(const name of [process.env.PLAYWRIGHT_MODULE,'playwright','playwright-core'].filter(Boolean)){try{api=require(name);break;}catch{}}
if(!api)throw Error('Install Playwright to run QA: npm install --no-save playwright && npx playwright install chromium (or set PLAYWRIGHT_MODULE to a playwright-core path)');
const launchOptions={headless:process.env.HEADFUL!=='1',args:['--no-sandbox','--ignore-gpu-blocklist','--enable-unsafe-swiftshader']};
if(process.env.CHROME_PATH)launchOptions.executablePath=process.env.CHROME_PATH;
else{
 // Fall back to any Chromium already present in the Playwright browser cache.
 const cache=process.env.PLAYWRIGHT_BROWSERS_PATH||path.join(process.env.LOCALAPPDATA||path.join(require('node:os').homedir(),'.cache'),'ms-playwright');
 try{for(const dir of fs.readdirSync(cache).filter(d=>/^chromium-\d+$/.test(d)).sort().reverse()){const exe=path.join(cache,dir,'chrome-win64','chrome.exe');if(fs.existsSync(exe)){launchOptions.executablePath=exe;break;}}}catch{}
}
const baseURL=`http://127.0.0.1:${process.env.QA_PORT||4173}/`;
module.exports={chromium:api.chromium,launchOptions,baseURL};
