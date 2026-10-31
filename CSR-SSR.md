# CSR-SSR.md — the same catalogue, built in two places

**Student:** 23120193 — Trần Kim Yến

Observed on 2026-10-30 with the starter's `server.mjs` on
`http://localhost:5050`, comparing `/?v=c` (built in the browser) with `/ssr`
(built by `renderSsrPage` in `server.mjs`). Screenshots are real Chrome
windows with DevTools on the Network panel, *Disable cache* ticked:
[`csr-requests-ssr.png`](evidence/csr-requests-ssr.png),
[`csr-requests-c.png`](evidence/csr-requests-c.png),
[`csr-nojs-ssr.png`](evidence/csr-nojs-ssr.png),
[`csr-nojs-c.png`](evidence/csr-nojs-c.png). View page source (`Ctrl+U`, the
`view-source:` page) of each URL is in
[`csr-source-c.png`](evidence/csr-source-c.png) (scrolled to lines 31–58) and
[`csr-source-ssr.png`](evidence/csr-source-ssr.png) (lines 1–26); the excerpts
below are copied from the same responses.

## 1. Where are the product names in each? Where is the stock value?

**`/?v=c` — not in the source.** View source shows the list empty at line 44
and the stock value as a dash at line 39 (`csr-source-c.png`); its Network
panel shows only the document and `favicon.ico` — View source runs no script:

```html
<p class="stock-total">Stock value: <output id="stock-value">—</output></p>
<p class="status" id="status" role="status"></p>
...
<ul class="catalogue" id="catalogue"></ul>
...
<template id="card-template">
  <li class="card" data-id="">
    <h2 class="name"></h2>
    <p class="price"></p>
  </li>
</template>
<script type="module" src="panel.js"></script>
```

No product name, price or `12.360.000 đ` appears anywhere in it. The only
`.name` is the empty one inside `<template>`. The names arrive later as JSON
from `/api/products`; the total is added up in the browser from eight
`/api/stock/:id` answers.

**`/ssr` — in the source.** View source shows `12.360.000 đ` at line 16 and
the first cards from line 19 (`csr-source-ssr.png`); all eight cards and the
total are already in the HTML:

```html
<p class="stock-total">Stock value: <output id="stock-value">12.360.000 đ</output></p>
<p class="status" id="status" role="status"></p>
<ul class="catalogue" id="catalogue">
  <li class="card" data-id="tshirt">
    <h2 class="name">T-shirt</h2>
    <p class="price">180.000 đ</p>
  </li>
  ...
  <li class="card" data-id="scarf">
    <h2 class="name">Scarf &lt;i&gt;limited&lt;/i&gt;</h2>
    <p class="price">160.000 đ</p>
  </li>
</ul>
```

There is no `<script>` at all in `/ssr`'s source.

## 2. Why does the scarf read `&lt;i&gt;` in `/ssr`'s source, and what does that share with `textContent`?

In `/ssr`'s View source the scarf is line 48:
`<h2 class="name">Scarf &lt;i&gt;limited&lt;/i&gt;</h2>`
([`csr-source-ssr-scarf.png`](evidence/csr-source-ssr-scarf.png)).
The name in `server.mjs` is the string `Scarf <i>limited</i>`. `renderSsrPage`
builds HTML by putting strings next to each other, so it passes the name
through `escapeHtml` first (line 81, `${escapeHtml(p.name)}`), which turns
`<` into `&lt;` and `>` into `&gt;`. The browser's HTML parser reads `&lt;` as
the character `<`, not as the start of a tag: the page shows
`Scarf <i>limited</i>` with the brackets visible and nothing in italics
(`csr-requests-ssr.png`). Without the escape the parser would have made a real
`<i>` element — the name would be treated as markup.

`textContent` reaches the same result from the other side. In version C the
card is filled with `card.querySelector('.name').textContent = p.name`, which
never goes through the HTML parser: it makes a text node. I checked the scarf's
`<h2>` on `/?v=c` after it loaded:

| Property | Value |
|---|---|
| `textContent` | `Scarf <i>limited</i>` |
| `innerHTML` | `Scarf &lt;i&gt;limited&lt;/i&gt;` |
| child nodes | one `#text`, no `<i>` element |

So when the browser turns the DOM C built back into HTML, it writes exactly
what `/ssr` sends: `&lt;i&gt;`. What they share: **data from the API is
treated as text, never as markup** — escaped by the server before parsing in
`/ssr`, kept out of the parser by `textContent` in the browser (brief item 6,
row 3). That is also what stops a product name from injecting a `<script>` or
an `onerror=` handler.

## 3. With JavaScript disabled, what is left of each?

JavaScript was turned off in Chrome's site settings for the page (the
crossed-out script icon shows in the address bar in both screenshots), then
each page was loaded.

- **`/ssr` — everything** ([`csr-nojs-ssr.png`](evidence/csr-nojs-ssr.png)):
  the heading, `Stock value: 12.360.000 đ` and all eight cards with names and
  prices, the scarf with its visible brackets — identical to the page with
  JavaScript on.
- **`/?v=c` — only the empty shell** ([`csr-nojs-c.png`](evidence/csr-nojs-c.png)):
  the toolbar, the heading `Catalogue` without `— version C`, the Test
  conditions panel with **`Server mode: unknown`** (nobody asked `/__mode`),
  `Stock value: —` and no cards, no status line. Network shows 3 requests:
  `?v=c`, `style.css`, `favicon.ico` — `panel.js` and `versions/c.js` are not
  even fetched, so neither `/api/products` nor any `/api/stock/…` request is
  ever made.

## 4. How many requests before the stock value appears? Which page is seen first?

Counted in DevTools → Network, *Disable cache*, page loaded once (bottom bar of
each screenshot):

| Page | Requests | What they are | Stock value on screen after |
|---|---|---|---|
| `/ssr` | **3** (`csr-requests-ssr.png`) | `ssr` (document, 2.1 kB, already holding the cards and `12.360.000 đ`), `style.css`, `favicon.ico` (404, the browser's own) | the first response — DOMContentLoaded 69 ms, finish 120 ms |
| `/?v=c` | **15** (`csr-requests-c.png`) | `?v=c`, `style.css`, `panel.js`, `__mode`, `c.js`, `products`, `favicon.ico`, then 8 × `/api/stock/:id` | the last stock answer — finish 627 ms |

Without the browser's own `favicon.ico` the counts are 2 and 14. In `/?v=c`
they come in four waves, each waiting for the one before: the HTML →
`panel.js` → `c.js` → `/api/products` → the 8 stock requests (in parallel, the
long green bars in the waterfall, 137–521 ms each).

**`/ssr` is seen first**, by a search engine and by a user on a slow phone.
A crawler that reads the HTML gets every name, price and the total from
`/ssr`; from `/?v=c` it gets the empty `<ul>` from question 1 unless it runs
the JavaScript. On a slow phone each of `/?v=c`'s four round trips adds its
full latency, and nothing is on screen until JavaScript has downloaded and
run; `/ssr` needs one round trip for its content.

## 5. When would you want the server to render, and when the browser?

Let the server render pages whose content must be there on the first response
— a public catalogue for search engines and slow phones, as `/ssr` showed with
3 requests and no JavaScript — and let the browser render the parts that
change after the page has loaded, such as Retry, a stock total that is
refreshed, or filters the user plays with, where fetching JSON is cheaper than
sending the whole page again.
