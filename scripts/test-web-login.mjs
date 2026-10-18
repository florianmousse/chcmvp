// Run after building test/support/web_login_harness.dart into build/login-preview.
// Uses only synthetic credentials in an isolated headless Chrome profile.
import { createServer } from 'node:http';
import { readFile, writeFile } from 'node:fs/promises';
import { resolve, extname, sep } from 'node:path';
import { spawn } from 'node:child_process';
import assert from 'node:assert/strict';
const root=resolve('build/login-preview');
const mime={'.html':'text/html','.js':'text/javascript','.wasm':'application/wasm','.json':'application/json','.css':'text/css','.png':'image/png','.otf':'font/otf'};
const server=createServer(async(req,res)=>{try {const url=new URL(req.url,'http://localhost'); const p=resolve(root,'.'+(url.pathname==='/'?'/index.html':url.pathname)); if(!p.startsWith(root+sep))throw Error(); const data=await readFile(p);res.writeHead(200,{'Content-Type':mime[extname(p)]||'application/octet-stream'});res.end(data);}catch{res.writeHead(404);res.end();}});
await new Promise(r=>server.listen(8086,'127.0.0.1',r));
const chrome=spawn(process.env.CHROME_EXECUTABLE || 'C:/Program Files/Google/Chrome/Application/chrome.exe',['--headless=new','--remote-debugging-port=9227','--user-data-dir='+resolve('build/chrome-login-check'),'--no-first-run','http://127.0.0.1:8086/'],{windowsHide:true,stdio:'ignore'});
const delay=ms=>new Promise(r=>setTimeout(r,ms));
let ws;
try {
 let tabs;
 for(let i=0;i<60;i++){try {tabs=await(await fetch('http://127.0.0.1:9227/json/list')).json();if(tabs.some(t=>t.url.startsWith('http://127.0.0.1:8086')))break;}catch{}await delay(500);}
 const target=tabs.find(t=>t.url.startsWith('http://127.0.0.1:8086'));
 ws=new WebSocket(target.webSocketDebuggerUrl); await new Promise(r=>ws.onopen=r);
 const pending=new Map();let n=0;
 ws.onmessage=e=>{const m=JSON.parse(e.data);if(m.id){pending.get(m.id)?.(m);pending.delete(m.id);}};
 const send=(method,params={})=>new Promise((resolve,reject)=>{const id=++n;pending.set(id,m=>m.error?reject(m.error):resolve(m.result));ws.send(JSON.stringify({id,method,params}));});
 const evaluate=async expression=>{const r=await send('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true}); if(r.exceptionDetails)throw Error(r.exceptionDetails.text);return r.result.value;};
 await send('Emulation.setDeviceMetricsOverride',{width:390,height:844,deviceScaleFactor:1,mobile:false});
 for(let i=0;i<60;i++){if(await evaluate('!!document.querySelector("#chc-login-email")'))break;await delay(500);}
 const fields=await evaluate('Array.from(document.querySelectorAll("#chc-login-form input")).map(i=>({name:i.name,type:i.type,autocomplete:i.autocomplete,width:i.getBoundingClientRect().width}))');
 assert.equal(fields.length,2);assert.equal(fields[0].autocomplete,'username');assert.equal(fields[1].autocomplete,'current-password');assert.equal(fields[1].type,'password');assert(fields.every(i=>i.width>0));
 console.log('Visible native login fields:',JSON.stringify(fields));
 await writeFile('build/login-mobile.png',Buffer.from((await send('Page.captureScreenshot',{format:'png'})).data,'base64'));
 await evaluate(`document.querySelector('#chc-login-email').value='demo@example.test'; document.querySelector('#chc-login-password').value='autofill-demo-value';document.querySelector('#chc-login-form').requestSubmit();`);
 await delay(500);
 assert(await evaluate('document.querySelector("#chc-login-form button[type=submit]").disabled'));
 assert.equal(await evaluate('document.body.getAttribute("data-login-result")'), 'AUTOFILL_OK');
 await writeFile('build/login-autofill-result.png',Buffer.from((await send('Page.captureScreenshot',{format:'png'})).data,'base64'));
 console.log('Autofill submission without input events reached Flutter; busy state enabled.');
 await send('Browser.close');
} finally {ws?.close();chrome.kill();await new Promise(r=>server.close(r));}
