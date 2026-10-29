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

## 2. Results

*Not run yet — filled in after the predictions commit.*
