/* Cookie-Banner und Meta-Pixel für die Webseite von Taleria.
 *
 * Das Pixel lädt NUR, wenn jemand auf „Akzeptieren“ tippt. Vorher geht keine
 * Anfrage an Meta. Die Wahl liegt nur im Browser (localStorage) und lässt sich
 * über „Cookie-Einstellungen“ unten auf jeder Seite ändern.
 * In der App gibt es kein Pixel und kein Tracking; diese Datei gehört nur zur Webseite.
 *
 * Pixel-ID eintragen (aus dem Meta Events Manager, eine Zahl, kein Geheimnis):
 */
var TALERIA_PIXEL_ID = '';

(function () {
  var KEY = 'taleria_consent_v1';

  function read() {
    try { return JSON.parse(localStorage.getItem(KEY) || 'null'); } catch (e) { return null; }
  }
  function save(choice) {
    try { localStorage.setItem(KEY, JSON.stringify({ marketing: choice, at: new Date().toISOString() })); } catch (e) {}
  }

  function loadPixel() {
    if (!TALERIA_PIXEL_ID || window.fbq) return;
    !function (f, b, e, v, n, t, s) {
      if (f.fbq) return; n = f.fbq = function () { n.callMethod ? n.callMethod.apply(n, arguments) : n.queue.push(arguments); };
      if (!f._fbq) f._fbq = n; n.push = n; n.loaded = !0; n.version = '2.0'; n.queue = [];
      t = b.createElement(e); t.async = !0; t.src = v; s = b.getElementsByTagName(e)[0]; s.parentNode.insertBefore(t, s);
    }(window, document, 'script', 'https://connect.facebook.net/en_US/fbevents.js');
    window.fbq('init', TALERIA_PIXEL_ID);
    window.fbq('track', 'PageView');
    // Anmeldung als Testfamilie angekommen: Seite danke.html
    if (/danke\.html$/.test(location.pathname)) window.fbq('track', 'Lead');
  }

  function hideBanner() {
    var b = document.getElementById('consent-banner');
    if (b) b.remove();
  }

  function showBanner() {
    if (!TALERIA_PIXEL_ID || document.getElementById('consent-banner')) return;
    var b = document.createElement('div');
    b.id = 'consent-banner';
    b.setAttribute('role', 'dialog');
    b.setAttribute('aria-label', 'Cookie-Einstellungen');
    b.innerHTML =
      '<div class="consent-box">' +
      '<p><strong>Darf Meta unsere Werbung messen?</strong> Mit deiner Zustimmung lädt diese Webseite das Meta-Pixel. ' +
      'Damit sehen wir, ob unsere Anzeigen auf Facebook und Instagram Eltern hierher bringen. ' +
      'In der App gibt es kein Tracking. <a href="datenschutz.html#meta-pixel">Mehr dazu</a></p>' +
      '<div class="consent-actions">' +
      '<button type="button" class="btn btn-ghost" data-consent="no">Ablehnen</button>' +
      '<button type="button" class="btn btn-gold" data-consent="yes">Akzeptieren</button>' +
      '</div></div>';
    b.addEventListener('click', function (ev) {
      var c = ev.target.getAttribute && ev.target.getAttribute('data-consent');
      if (!c) return;
      var yes = c === 'yes';
      var before = read();
      save(yes);
      hideBanner();
      if (yes) loadPixel();
      // Widerruf: Das Pixel ist schon geladen, darum Seite neu laden, damit es weg ist.
      else if (before && before.marketing && window.fbq) location.reload();
    });
    document.body.appendChild(b);
  }

  document.addEventListener('click', function (ev) {
    var t = ev.target.closest && ev.target.closest('[data-consent-open]');
    if (!t) return;
    ev.preventDefault();
    if (!TALERIA_PIXEL_ID) { alert('Diese Webseite nutzt zurzeit keine Cookies und kein Pixel.'); return; }
    showBanner();
  });

  function start() {
    var c = read();
    if (c && c.marketing === true) loadPixel();
    else if (!c) showBanner();
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start);
  else start();
})();
