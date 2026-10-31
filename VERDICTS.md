# VERDICTS.md — Three answers to one brief

**Student:** 23120193 — Trần Kim Yến

## 1. Predictions (from reading alone, before any run)

Written from reading `public/versions/a.js`, `b.js` and `c.js` beside
`brief.md`, before the server was started. Drafted with Claude Code from the
code, read and approved by me (see `AI-LOG.md`). This section is not edited
after this commit; where the runs disagree, section 2 says so.

### Version A — predicted verdict: fix

- Row 2 will fail. Lines 51–56 start the stock requests with `products.forEach(async (p) => { … })`. `forEach` does not wait for the async callbacks, so line 56 writes `formatVnd(total)` while `total` is still 0. I expect `Stock value: 0 đ` in mode `normal`.
- The eight stock requests should still go out at the same moment, so the parallel check should pass.
- Mode `empty` should show `0 đ`, but only by accident: the total is never awaited.
- Rows 1, 3–7 and 8 should pass: `AbortSignal.timeout(5000)` on line 14, `textContent` on lines 30–31, `list.replaceChildren()` in `catch`.
- Unsure: if a stock request ever failed, the detached callbacks would give `Uncaught (in promise)` (row 7). With this server every id exists, so I expect no red line.

### Version B — predicted verdict: fix

- Row 6 will fail. Line 16 passes `{ timeout: 5000 }` to `fetch`, but `fetch` has no `timeout` option. In mode `hang` I expect `Loading products…` for the full 30 s, then `Could not load products.` when the server answers 504.
- Row 8 will probably fail too: with `// @ts-check`, an object literal with an unknown property `timeout` should be underlined because `RequestInit` has no such key.
- Rows 1–5, 7 and empty should pass: `Promise.all` on line 51 keeps the stock requests parallel and waits for them; the list is cleared at the start of each attempt (line 42).

### Version C — predicted verdict: keep

- All rows should pass: `AbortSignal.timeout(5000)` on line 16, `Promise.all` on line 54 waits for parallel stock requests, `textContent` on lines 33–34, `catch` clears the list and shows Retry.
- Unsure: with `"strict": false` in `jsconfig.json`, I do not expect `firstElementChild` (possibly null) to be underlined in row 8 for A, B or C.

## 2. Results on the original versions

Run on 2026-10-29, 22:26–22:28, against the untouched `server.mjs` on
`http://localhost:5050` (Node v24.16.0). Every number below is in
[`evidence/run-original.txt`](evidence/run-original.txt), which also says how
the rows were run: a script drives the real page in Chromium and reads what it
shows; row 8 is `tsc --project jsconfig.json` with `// @ts-check` added to one
file at a time.

The screenshots of the failing rows (`a-row2.png`, `b-row6.png`,
`b-row6-at30s.png`, `b-row8.png`) I took myself on 2026-10-31, in my own Chrome
with DevTools on the Network panel and in VS Code, against the original files
(the server started from the untouched starter). Looking at each failing row
by hand matched the scripted run. `b-row8-tsc.png` is the same row 8 from
`tsc` in PowerShell, captured by `tools/row8-shot.ps1`.

Note on row 7: in Chrome every page also shows a red
`GET /favicon.ico 404 (Not Found)` line. That is the browser asking for a tab
icon the starter server does not have — the browser reporting the network,
like the `GET … 500` line the README mentions — not the version's code.

### Version A — verdict: **fix** (decided by row 2)

| Row | Result | What I saw |
|---|---|---|
| 1 | PASS | `normal`: 8 cards in API order (`tshirt` … `scarf`), prices `180.000 đ`, `420.000 đ` …, `#status` empty |
| 2 | **FAIL** | `normal`, at 1.5 s: **`Stock value: 0 đ`**, expected `12.360.000 đ`. Network shows all 8 `/api/stock/…` requests answered `200` (initiator `a.js:20`); the last one ended at 930 ms, after the total had already been written |
| 3 | PASS | last card reads `Scarf <i>limited</i>`, 0 `<i>` elements inside it |
| 4 | PASS | `slow`: `Loading products…` at 1 s, 8 cards at 3035 ms, status cleared (stock still `0 đ` — the row 2 bug) |
| 5 | PASS | `error`: `Could not load products.`, Retry shown, 0 cards; `normal` + Retry: 8 cards, message and button gone |
| 6 | PASS | `hang`: `Could not load products.` + Retry at 5099 ms; server: `no answer: the browser gave up after 5009 ms` |
| 7 | PASS | no `Uncaught …`, no unhandled rejection, no `console.error`; only the browser's own `500` (and favicon `404`) lines |
| 8 | PASS | `// @ts-check` on `a.js`: `tsc` exit 0, nothing reported |
| empty | PASS | `No products yet.`, 0 cards, `0 đ` |
| parallel | PASS | 8 stock requests started at 50–52 ms (spread 2 ms), no staircase |

- **Line(s) responsible:** `public/versions/a.js` lines 51–56:
  ```js
  let total = 0;
  products.forEach(async (p) => {
    const stock = await getStock(p.id);
    total += p.price * stock;
  });
  stockValue.textContent = formatVnd(total);
  ```
  `forEach` ignores the promises its async callback returns, so line 56 runs
  straight away with `total` still 0, and nothing writes the total again.
- **Evidence:** [`evidence/a-row2.png`](evidence/a-row2.png) — `normal`,
  `Stock value: 0 đ`; Network: `products` and all 8 `/api/stock/…` requests
  `200` (initiator `a.js:20`), their waterfall bars starting together.
- **The one sentence for the assistant:** *"Row 2 fails: in mode normal the page shows Stock value: 0 đ instead of 12.360.000 đ because products.forEach(async …) on a.js lines 52–55 is not awaited, so line 56 writes the total while it is still 0 — wait for every stock response before writing the total, keep the eight /api/stock/… requests going out in parallel (no await inside a loop), and change nothing else."*

### Version B — verdict: **fix** (decided by row 6, also row 8)

| Row | Result | What I saw |
|---|---|---|
| 1 | PASS | `normal`: 8 cards in API order, prices as A, `#status` empty |
| 2 | PASS | `normal`, at 1.5 s: `12.360.000 đ` |
| 3 | PASS | last card reads `Scarf <i>limited</i>`, 0 `<i>` elements |
| 4 | PASS | `slow`: `Loading products…` at 1 s, 8 cards at 3050 ms, status cleared, `12.360.000 đ` |
| 5 | PASS | `error`: message + Retry, 0 cards; `normal` + Retry: 8 cards, message and button gone, `12.360.000 đ` |
| 6 | **FAIL** | `hang`: still **`Loading products…`, no Retry** at 5.5 s, 7 s, 15 s and 25 s; Network shows `products` **(pending)** (initiator `b.js:16`). Only at **30.01 s**, when the server answered `504` (`-> 504 30009 ms` in its log), did the page show `Could not load products.` |
| 7 | PASS | no `Uncaught …`, nothing from the page; the browser's own `500` line and, at 30 s in row 6, its own `504 (Gateway Timeout)` line |
| 8 | **FAIL** | `// @ts-check` on `b.js`: `public/versions/b.js:17:51 - error TS2353: Object literal may only specify known properties, and 'timeout' does not exist in type 'RequestInit'.` (line 17 because `@ts-check` became line 1; it is line 16 of the file) |
| empty | PASS | `No products yet.`, 0 cards, `0 đ` |
| parallel | PASS | 8 stock requests started at 58–59 ms (spread 1 ms) |

- **Line(s) responsible:** `public/versions/b.js` line 16:
  ```js
  const response = await fetch('/api/products', { timeout: 5000 });
  ```
  `fetch` has no `timeout` option; the browser ignores the unknown key, so
  nothing ever aborts the request, and TypeScript rejects the key against
  `RequestInit`.
- **Evidence:** [`evidence/b-row6.png`](evidence/b-row6.png) — `hang`,
  page `Loading products…` and `Stock value: —`, no Retry; Network:
  `products` **(pending)**, initiator `b.js:16`.
  [`evidence/b-row6-at30s.png`](evidence/b-row6-at30s.png) — the same page
  load later (the other rows' times are identical: `?v=b` 15 ms, `b.js`
  12 ms): `products` **504** after **30.01 s**, `Finish: 30.07 s`, and only
  then `Could not load products.` + Retry — so nothing gave up at 5 s.
  [`evidence/b-row8.png`](evidence/b-row8.png) — VS Code with the folder
  open, `// @ts-check` on line 1 of `b.js`: `timeout` underlined, hover and
  Problems panel `Object literal may only specify known properties, and
  'timeout' does not exist in type 'RequestInit'. ts(2353) [Ln 17, Col 51]`.
  Same result from `tsc` in PowerShell:
  [`evidence/b-row8-tsc.png`](evidence/b-row8-tsc.png).
- **The one sentence for the assistant:** *"Rows 6 and 8 fail: in mode hang the page still says Loading products… after 7 s, Network shows /api/products pending until the 504 at 30 s, and // @ts-check underlines timeout with TS2353, because fetch has no timeout option (b.js line 16) — make the products request give up after 5 seconds so the catch shows Could not load products. and Retry, keep the stock requests parallel, and change nothing else."*

### Version C — verdict: **keep** (every row passes)

| Row | Result | What I saw |
|---|---|---|
| 1 | PASS | `normal`: 8 cards in API order, prices as A, `#status` empty |
| 2 | PASS | `normal`, at 1.5 s: `12.360.000 đ` |
| 3 | PASS | last card reads `Scarf <i>limited</i>`, 0 `<i>` elements |
| 4 | PASS | `slow`: `Loading products…` at 1 s, 8 cards at 3069 ms, status cleared, `12.360.000 đ` |
| 5 | PASS | `error`: message + Retry, 0 cards; `normal` + Retry: 8 cards, message and button gone |
| 6 | PASS | `hang`: `Could not load products.` + Retry at 5085 ms; server: `the browser gave up after 5002 ms` |
| 7 | PASS | no `Uncaught …`, nothing from the page; only the browser's own `500` line |
| 8 | PASS | `// @ts-check` on `c.js`: `tsc` exit 0 |
| empty | PASS | `No products yet.`, 0 cards, `0 đ` |
| parallel | PASS | 8 stock requests started at 42–43 ms (spread 1 ms) |

- **Line(s) responsible:** none.
- **Evidence:** no failing row, so no screenshot; numbers in `evidence/run-original.txt`.
- **The one sentence for the assistant:** none needed — C is kept as it is. If asked, I would say: *"Leave c.js unchanged: it passes rows 1–8, empty and the parallel check."*

### Predictions against the table

- **A:** right — row 2 failed with `0 đ`, everything else passed. The doubt
  about row 7 did not show up: every stock request succeeded, so no detached
  promise rejected. (Whether it would is checked in `ASSISTANT-REVIEW.md`.)
- **B:** right on row 6. Row 8 was marked "probably"; the run confirmed it.
  One thing the prediction did not say: B does recover after 30 s, because
  the server's `504` lands in `catch` — the row still fails, since it asks
  for the message after about 5 s.
- **C:** right — keep. The doubt about `firstElementChild` and row 8 was
  unfounded with `"strict": false`: `tsc` reported nothing for A or C.

## 3. Summary

| Version | Predicted | Failing rows | Verdict | Evidence |
|---|---|---|---|---|
| A | fix | 2 | **fix** | `evidence/a-row2.png` |
| B | fix | 6, 8 | **fix** | `evidence/b-row6.png` (+ `b-row6-at30s.png`), `evidence/b-row8.png` (+ `b-row8-tsc.png`) |
| C | keep | — | **keep** | — |

## 4. After the fixes — the whole table again

Fix A (`3385d84`) and fix B (`274e790`) each touch only their own file; C is
unchanged. The whole table was run again on the final files on 2026-10-30
around 22:25 ([`evidence/run-after-fixes.txt`](evidence/run-after-fixes.txt)).

| Row | A (fixed) | B (fixed) | C (kept) |
|---|---|---|---|
| 1 | PASS — 8 cards, API order | PASS | PASS |
| 2 | **PASS — `12.360.000 đ`** (was `0 đ`) | PASS — `12.360.000 đ` | PASS — `12.360.000 đ` |
| 3 | PASS — `Scarf <i>limited</i>` | PASS | PASS |
| 4 | PASS — cards at 3062 ms | PASS — cards at 3020 ms | PASS — cards at 3088 ms |
| 5 | PASS | PASS | PASS |
| 6 | PASS — message + Retry at 5092 ms | **PASS — message + Retry at 5042 ms** (was 30042 ms) | PASS — 5069 ms |
| 7 | PASS — nothing from the page | PASS | PASS |
| 8 | PASS — `tsc` exit 0 | **PASS — `tsc` exit 0** (was TS2353) | PASS — `tsc` exit 0 |
| empty | PASS — `No products yet.`, `0 đ` | PASS | PASS |
| parallel | PASS — 8 starts within 1 ms | PASS — within 2 ms | PASS — within 1 ms |

Neither fix broke another row. Fix A also removes the `Uncaught (in promise)`
that `ASSISTANT-REVIEW.md` produced by forcing a stock request to fail: the
stock requests are now awaited inside `try`, so a failure reaches `catch`
(re-run at the end of `evidence/run-after-fixes.txt`: message + Retry, no page error).
