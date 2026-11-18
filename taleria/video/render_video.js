const { chromium } = require('playwright');
const fs = require('fs'), path = require('path');
(async () => {
  const [dir, w, h, mode, out] = process.argv.slice(2);
  const vo = JSON.parse(fs.readFileSync(path.join(dir, 'vo.json'), 'utf8'));
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: +w, height: +h }, deviceScaleFactor: 1 });
  await page.addInitScript(d => { window.VO = d; }, { durs: vo.durs, words: vo.words });
  await page.goto('file://' + path.join(dir, 'video.html') + `?w=${w}&h=${h}`);
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(800);
  const timing = await page.evaluate(() => window.TIMING);
  fs.writeFileSync(path.join(dir, 'timing.json'), JSON.stringify(timing));
  fs.writeFileSync(path.join(dir, 'sfx.json'), JSON.stringify(await page.evaluate(() => window.SFX)));
  fs.mkdirSync(out, { recursive: true });
  if (mode === 'preview') {
    const ts = timing.starts.map(s => s + 2.6);
    for (const [i, t] of ts.entries()) {
      await page.evaluate(t => window.render(t), t);
      await page.screenshot({ path: `${out}/p${i + 1}.jpg`, type: 'jpeg', quality: 80 });
    }
  } else {
    const n = Math.ceil(timing.total * 30);
    for (let f = 0; f < n; f++) {
      await page.evaluate(t => window.render(t), f / 30);
      await page.screenshot({ path: `${out}/f${String(f).padStart(5, '0')}.jpg`, type: 'jpeg', quality: 90 });
    }
  }
  console.log('fertig', timing.total.toFixed(1));
  await browser.close();
})();
