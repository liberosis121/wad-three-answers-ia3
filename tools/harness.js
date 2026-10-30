// Done means harness for IA#3. Kept OUTSIDE session5/ so the submission's
// scope stays clean. Paste into the console (or a browser automation tool) of
// http://localhost:5050/ while `node server.mjs` runs; it drives the real page
// in an iframe, switches the server mode through POST /__mode exactly like the
// Test conditions buttons, and reads only what the page shows.
//
//   await H.run('a')            rows 1-7 + empty + parallel for version A
//   await H.run('b', {hangMs: 32000})   wait out the 30 s hang as well
//
// Row 8 (tsc) is run separately from the shell.

window.H = (() => {
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const setMode = async (mode) => {
    const res = await fetch('/__mode', {
      method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ mode }),
    });
    return (await res.json()).mode;
  };

  async function open(v) {
    const f = document.createElement('iframe');
    f.style.cssText = 'width:1000px;height:700px';
    const errors = [];
    document.body.append(f);
    f.src = `/?v=${v}&run=${Date.now()}`;
    // Hook errors as early as the new document exists.
    await new Promise((resolve) => {
      const tick = () => {
        const w = f.contentWindow;
        if (w && w.location.href !== 'about:blank' && w.document.readyState !== 'uninitialized') {
          w.addEventListener('error', (e) => errors.push(`error: ${e.message}`));
          w.addEventListener('unhandledrejection', (e) => errors.push(`unhandledrejection: ${e.reason}`));
          const orig = w.console.error.bind(w.console);
          w.console.error = (...a) => { errors.push(`console.error: ${a.join(' ')}`); orig(...a); };
          resolve();
        } else setTimeout(tick, 5);
      };
      tick();
    });
    const t0 = performance.now();
    return { f, w: f.contentWindow, get d() { return f.contentDocument; }, errors, t0, at: () => Math.round(performance.now() - t0) };
  }

  const snap = (d) => (!d || !d.querySelector('#status')) ? { status: null, cards: 0, retryHidden: true, stock: null } : ({
    status: d.querySelector('#status').textContent,
    cards: d.querySelectorAll('#catalogue .card').length,
    ids: [...d.querySelectorAll('#catalogue .card')].map((c) => c.dataset.id).join(','),
    lastName: d.querySelector('#catalogue .card:last-child .name')?.textContent ?? null,
    lastNameItalics: d.querySelectorAll('#catalogue .card:last-child .name i').length,
    prices: [...d.querySelectorAll('#catalogue .price')].map((p) => p.textContent).join(' | '),
    stock: d.querySelector('#stock-value').textContent,
    retryHidden: d.querySelector('#retry').hidden,
  });

  // Poll until pred(snapshot) is true or `limit` ms pass; returns {ms, s}.
  async function until(x, pred, limit, step = 50) {
    while (x.at() < limit) {
      const s = snap(x.d);
      if (pred(s)) return { ms: x.at(), s };
      await sleep(step);
    }
    return { ms: null, s: snap(x.d) };
  }

  async function run(v, { hangMs = 7000 } = {}) {
    const out = { version: v, rows: {} };
    const allErrors = [];

    // Rows 1, 2, 3 and the parallel check: mode normal.
    await setMode('normal');
    let x = await open(v);
    await sleep(1500);
    const n = snap(x.d);
    const stock = x.w.performance.getEntriesByType('resource')
      .filter((e) => e.name.includes('/api/stock/'))
      .map((e) => ({ id: e.name.split('/').pop(), start: Math.round(e.startTime), end: Math.round(e.responseEnd) }));
    const starts = stock.map((s) => s.start);
    const products = x.w.performance.getEntriesByType('resource').find((e) => e.name.endsWith('/api/products'));
    out.rows.r1 = n;
    out.rows.r2 = { stockAt1500ms: n.stock };
    out.rows.r3 = { lastName: n.lastName, italicTags: n.lastNameItalics };
    out.parallel = {
      count: stock.length,
      productsEnd: products ? Math.round(products.responseEnd) : null,
      starts: stock.map((s) => `${s.id}@${s.start}`).join(' '),
      spreadMs: starts.length ? Math.max(...starts) - Math.min(...starts) : null,
      lastStockEnd: stock.length ? Math.max(...stock.map((s) => s.end)) : null,
    };
    allErrors.push(...x.errors.map((e) => `[normal] ${e}`));
    x.f.remove();

    // Row 4: mode slow.
    await setMode('slow');
    x = await open(v);
    await sleep(1000);
    const slow1s = snap(x.d).status;
    const slowDone = await until(x, (s) => s.cards === 8, 6000);
    await sleep(1500);   // was 800 ms: the slowest stock answer can land ~830 ms after the cards
    out.rows.r4 = { statusAt1s: slow1s, cardsAt: slowDone.ms, after: snap(x.d) };
    allErrors.push(...x.errors.map((e) => `[slow] ${e}`));
    x.f.remove();

    // Row 5: mode error, then normal + Retry.
    await setMode('error');
    x = await open(v);
    await sleep(800);
    const err = snap(x.d);
    await setMode('normal');
    x.d.querySelector('#retry').click();
    await sleep(1500);
    out.rows.r5 = { onError: err, afterRetry: snap(x.d) };
    allErrors.push(...x.errors.map((e) => `[error+retry] ${e}`));
    x.f.remove();

    // Row 6: mode hang.
    await setMode('hang');
    x = await open(v);
    const samples = [];
    let gaveUpAt = null;
    while (x.at() < hangMs) {
      const s = snap(x.d);
      if (gaveUpAt === null && s.status === 'Could not load products.' && !s.retryHidden) gaveUpAt = x.at();
      if ([1000, 3000, 5500, 7000, 15000, 25000, 31000].some((t) => Math.abs(x.at() - t) < 130 && !samples.find((q) => q.t === t))) {
        const t = [1000, 3000, 5500, 7000, 15000, 25000, 31000].find((tt) => Math.abs(x.at() - tt) < 130);
        samples.push({ t, status: s.status, retryHidden: s.retryHidden });
      }
      await sleep(100);
    }
    out.rows.r6 = { gaveUpAt, samples, end: snap(x.d) };
    allErrors.push(...x.errors.map((e) => `[hang] ${e}`));
    x.f.remove();

    // Empty row.
    await setMode('empty');
    x = await open(v);
    await sleep(1000);
    out.rows.empty = snap(x.d);
    allErrors.push(...x.errors.map((e) => `[empty] ${e}`));
    x.f.remove();

    out.rows.r7 = { pageErrors: allErrors };
    await setMode('normal');
    return out;
  }

  return { run, setMode };
})();
