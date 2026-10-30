// Fault injection used for ASSISTANT-REVIEW.md: run in the console of http://localhost:5050/
// (server in mode normal). Loads each original version in an iframe whose fetch answers 404
// for /api/stock/cap only, then reports what the page shows and any page errors.
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
async function stockFail(v) {
  const f = document.createElement('iframe');
  const errors = [];
  document.body.append(f);
  f.src = `/?v=${v}&fault=${Date.now()}`;
  await new Promise((resolve) => {
    const tick = () => {
      const w = f.contentWindow;
      if (w && w.location.href !== 'about:blank') {
        w.addEventListener('error', (e) => errors.push('error: ' + e.message));
        w.addEventListener('unhandledrejection', (e) => errors.push('unhandledrejection: ' + e.reason));
        const orig = w.fetch.bind(w);
        w.fetch = (u, o) => String(u).includes('/api/stock/cap')
          ? Promise.resolve(new w.Response('{"error":"Unknown product id: cap"}', { status: 404, headers: { 'Content-Type': 'application/json' } }))
          : orig(u, o);
        resolve();
      } else setTimeout(tick, 5);
    };
    tick();
  });
  await sleep(1500);
  const d = f.contentDocument;
  const out = {
    version: v, status: d.querySelector('#status').textContent,
    cards: d.querySelectorAll('#catalogue .card').length,
    stock: d.querySelector('#stock-value').textContent,
    retryHidden: d.querySelector('#retry').hidden, pageErrors: errors,
  };
  f.remove();
  return out;
}
const res = [];
for (const v of ['a', 'b', 'c']) res.push(await stockFail(v));
console.table(res);
