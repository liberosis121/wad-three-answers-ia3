// Navigate the first page tab of a Chrome started with --remote-debugging-port.
// Usage: node cdp-nav.mjs <port> <url> [scrollY]
// With scrollY, waits for the page to load and then scrolls it (used for view-source pages).
const [port, url, scrollY] = process.argv.slice(2);
const targets = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
const page = targets.find((t) => t.type === 'page' && !t.url.startsWith('devtools://'));
if (!page) throw new Error('no page target');
const ws = new WebSocket(page.webSocketDebuggerUrl);
await new Promise((r) => ws.addEventListener('open', r, { once: true }));
let id = 0;
const send = (method, params = {}) => new Promise((resolve) => {
  const myId = ++id;
  const onMsg = (e) => { const m = JSON.parse(e.data); if (m.id === myId) { ws.removeEventListener('message', onMsg); resolve(m); } };
  ws.addEventListener('message', onMsg);
  ws.send(JSON.stringify({ id: myId, method, params }));
});
await send('Page.navigate', { url });
if (scrollY) {
  await new Promise((r) => setTimeout(r, 3000));
  const res = await send('Runtime.evaluate', { expression: `window.scrollTo(0, ${Number(scrollY)}); window.scrollY` });
  console.log(`scrolled to ${JSON.stringify(res.result?.result?.value)}`);
}
ws.close();
console.log(`navigated ${page.id} to ${url}`);
