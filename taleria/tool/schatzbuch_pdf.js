// Erzeugt schatzbuch/schatzbuch_teil1.pdf und elternheft_teil1.pdf aus den HTML-Dateien und meldet Seiten, die überlaufen.
// Aufruf im Ordner taleria/:  node tool/schatzbuch_pdf.js
const { chromium } = require('playwright');
const path = require('path');
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage();
  for (const name of ['schatzbuch_teil1', 'elternheft_teil1']) {
  await p.goto('file://' + path.resolve(`schatzbuch/${name}.html`), { waitUntil: 'networkidle' });
  await p.evaluate(() => document.fonts.ready);
  const over = await p.$$eval('section.page', (s) =>
    s.map((x, i) => [i + 1, x.scrollHeight - x.clientHeight]).filter(([, d]) => d > 2));
  const broken = await p.$$eval('img', (i) => i.filter((x) => !x.naturalWidth).map((x) => x.getAttribute('src')));
  console.log(name, 'Seiten:', await p.$$eval('section.page', (s) => s.length), '| zu voll:', JSON.stringify(over), '| fehlende Bilder:', broken);
  await p.pdf({ path: `schatzbuch/${name}.pdf`, format: 'A4', printBackground: true, preferCSSPageSize: true });
  }
  await b.close();
})();
