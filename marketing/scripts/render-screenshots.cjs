const {chromium}=require(process.env.PLAYWRIGHT_CORE_PATH || '/opt/homebrew/lib/node_modules/openclaw/node_modules/playwright-core');
const fs=require('fs'),path=require('path');
const root=path.resolve(__dirname,'../app-store/de-DE');
(async()=>{
 const browser=await chromium.launch({executablePath:process.env.CHROME_PATH || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless:true});
 try{
  for(const [kind,w,h] of [['large',1320,2868],['medium',1206,2622]]){
   if(process.argv[2] && process.argv[2]!==kind)continue;
   fs.mkdirSync(path.join(root,'screenshots',kind),{recursive:true});
   const page=await browser.newPage({viewport:{width:w,height:h},deviceScaleFactor:1});
   for(let i=1;i<=5;i++){
    await page.goto('file://'+path.join(root,'template.html')+'?kind='+kind+'&screen='+i);
    await page.waitForFunction(()=>Array.from(document.images).every(x=>x.complete&&x.naturalWidth>0));
    await page.evaluate(()=>document.fonts.ready);
    const fit=await page.evaluate(()=>{const h=document.querySelector('h1'),p=document.querySelector('.sub');return {title:h.getBoundingClientRect().bottom,sub:p.getBoundingClientRect().bottom,phone:document.querySelector('.phone').getBoundingClientRect().top}});
    if(fit.sub>=fit.phone)throw Error('Overlapping copy '+JSON.stringify(fit));
    const file=path.join(root,'screenshots',kind,String(i).padStart(2,'0')+'.jpg');
    await page.screenshot({path:file,type:'jpeg',quality:98,fullPage:false});
    console.log(kind,i,JSON.stringify(fit));
   }
   await page.close();
  }
  if(!process.argv[2] || process.argv[2]==='preview') {
   const page=await browser.newPage({viewport:{width:2000,height:1980},deviceScaleFactor:1});
   await page.goto('file://'+path.join(root,'overview.html'));
   await page.waitForFunction(()=>Array.from(document.images).every(x=>x.complete&&x.naturalWidth>0));
   await page.screenshot({path:path.join(root,'preview.jpg'),type:'jpeg',quality:95,fullPage:true});
   await page.close();
  }
 }finally{await browser.close()}
})();
