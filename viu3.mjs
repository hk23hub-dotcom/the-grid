import { chromium } from 'playwright-core';
const b = await chromium.launch({ executablePath:'/opt/pw-browsers/chromium-1194/chrome-linux/chrome', args:['--no-sandbox','--use-gl=swiftshader'] });
const errs=[]; const F='file:///home/user/the-grid/hk23-universe.html';
const pg = await b.newPage({viewport:{width:1360,height:880}});
pg.on('pageerror', e=>{ if(!/localStorage/.test(e.message)) errs.push(e.message); });
// sólo siembra si NO existe — así la recarga conserva lo que él guardó
await pg.addInitScript(()=>{ if(!localStorage.getItem('hk23_tier')) localStorage.setItem('hk23_tier', JSON.stringify('socio')); });
await pg.goto(F); await pg.waitForTimeout(1600);
await pg.evaluate(async ()=>{ await window.Inquilinos.open(); await new Promise(x=>setTimeout(x,600));
  const s=(k,v)=>document.getElementById('ia-'+k).value=v;
  s('name','JEAN CHRISTOPHE'); s('slug','jean-christophe'); s('code','MVB-JC'); s('sub','plugins, sets y noche');
  document.getElementById('ia-create').click(); await new Promise(x=>setTimeout(x,1200));
  document.getElementById('ia-close').click(); });
const r={};
r.created = await pg.evaluate(async ()=>{ window.Inquilinos.galaxy('jean-christophe'); await new Promise(s=>setTimeout(s,900));
  document.getElementById('iu-enter').click(); await new Promise(s=>setTimeout(s,800));
  document.getElementById('iu-editbtn').click(); await new Promise(s=>setTimeout(s,300));
  const cv=document.getElementById('iu-cv'), rc=cv.getBoundingClientRect();
  const tap=(fx,fy)=>cv.dispatchEvent(new MouseEvent('mousedown',{clientX:rc.left+rc.width*fx, clientY:rc.top+rc.height*fy, bubbles:true}));
  tap(0.24,0.30); document.getElementById('iu-nlabel').value='mis sets';
  document.getElementById('iu-nsub').value='mixes y grabaciones'; document.getElementById('iu-nsave').click();
  await new Promise(s=>setTimeout(s,600));
  tap(0.75,0.58); document.getElementById('iu-nlabel').value='mis plugins';
  document.getElementById('iu-nsub').value='herramientas propias'; document.getElementById('iu-nsave').click();
  await new Promise(s=>setTimeout(s,600));
  tap(0.5,0.78); document.getElementById('iu-nlabel').value='la noche';
  document.getElementById('iu-nsub').value='fechas y line-ups'; document.getElementById('iu-nsave').click();
  await new Promise(s=>setTimeout(s,800));
  const stored=JSON.parse(localStorage.getItem('hk23_inquilinos')||'[]').find(x=>x.slug==='jean-christophe');
  return { live:window.InqUniverse.nodes().length, storedNodes:(stored&&stored.nodes||[]).length,
    labels:(stored&&stored.nodes||[]).map(n=>n.label) }; });
await pg.evaluate(()=>document.getElementById('iu-done').click());
await pg.waitForTimeout(600);
await pg.screenshot({path:'/tmp/claude-0/-home-user-the-grid/324a8d95-1dde-5ff9-896a-63a9fd0b2cd7/scratchpad/shot-iu-world.png'});
// RECARGA real, sin pisar el storage
await pg.reload(); await pg.waitForTimeout(1900);
r.afterReload = await pg.evaluate(async ()=>{ window.Inquilinos.galaxy('jean-christophe'); await new Promise(s=>setTimeout(s,1100));
  document.getElementById('iu-enter').click(); await new Promise(s=>setTimeout(s,700));
  return { n:window.InqUniverse.nodes().length, labels:window.InqUniverse.nodes().map(x=>x.label) }; });
// mover un nodo persiste
r.dragPersists = await pg.evaluate(async ()=>{
  document.getElementById('iu-editbtn').click(); await new Promise(s=>setTimeout(s,250));
  const n0=window.InqUniverse.nodes()[0], before={x:n0.x,y:n0.y};
  const cv=document.getElementById('iu-cv'), rc=cv.getBoundingClientRect();
  cv.dispatchEvent(new MouseEvent('mousedown',{clientX:rc.left+n0.x*rc.width, clientY:rc.top+n0.y*rc.height, bubbles:true}));
  cv.dispatchEvent(new MouseEvent('mousemove',{clientX:rc.left+rc.width*0.42, clientY:rc.top+rc.height*0.2, bubbles:true}));
  dispatchEvent(new MouseEvent('mouseup',{bubbles:true}));
  await new Promise(s=>setTimeout(s,700));
  const stored=JSON.parse(localStorage.getItem('hk23_inquilinos')||'[]').find(x=>x.slug==='jean-christophe');
  const after=(stored.nodes||[])[0];
  return { moved: Math.abs(after.x-before.x)>0.05, storedX:+after.x.toFixed(3) }; });
await pg.screenshot({path:'/tmp/claude-0/-home-user-the-grid/324a8d95-1dde-5ff9-896a-63a9fd0b2cd7/scratchpad/shot-iu-final.png'});
console.log(JSON.stringify({r,errs},null,1));
await b.close();
