// Erzeugt pitch/taleria_pitch.pdf aus pitch/taleria_pitch.html und meldet Seiten, die überlaufen.
// Aufruf im Ordner taleria/:  node tool/pitch_pdf.js
const { chromium } = require('playwright');
const path = require('path');
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 794, height: 1123 } });
  await p.goto('file://' + path.resolve('pitch/taleria_pitch.html'), { waitUntil: 'networkidle' });
  await p.evaluate(() => document.fonts.ready);
  const over = await p.$$eval('section.slide', (s) =>
    s.map((x, i) => {
      const box = x.getBoundingClientRect();
      const kids = [...x.querySelectorAll('*')].filter((k) => !k.closest('.foot') && !k.closest('.fan') && getComputedStyle(k).position !== "absolute" && !k.classList.contains("grow") && !k.closest(".grow:not(.mid)"));
      const bottom = Math.max(...kids.map((k) => k.getBoundingClientRect().bottom));
      return [i + 1, Math.round(bottom - (box.bottom - 8))];
    }).filter(([, d]) => d > 0));
  const broken = await p.$$eval('img', (i) => i.filter((x) => !x.naturalWidth).map((x) => x.getAttribute('src')));
  console.log('Seiten:', await p.$$eval('section.slide', (s) => s.length), '| zu voll:', JSON.stringify(over), '| fehlende Bilder:', broken);
  await p.pdf({ path: 'pitch/taleria_pitch.pdf', printBackground: true, preferCSSPageSize: true });
  await b.close();
})();
