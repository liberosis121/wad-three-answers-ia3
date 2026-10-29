# ASSISTANT-REVIEW.md — an assistant's review, checked against the rows

**Student:** 23120193 — Trần Kim Yến

- **Tool and model:** Claude Code (desktop app), a fresh `general-purpose`
  subagent, model Claude Opus 5.5. It started with no conversation history.
- **When:** 2026-10-29, about 23:05, after my table was run but **before the
  assistant was told any verdict**: the prompt below is everything it got.
- **Isolation:** it could read only a temporary folder holding `brief.md` and
  the three original files (`git show 3676f2f:…`), not the repository, so it
  could not see `VERDICTS.md` or the evidence. It ran nothing.

## 1. The prompt

~~~~text
Read ONLY these four files and nothing else on disk (do not search, list or open any other folder or file, and do not run anything):

C:/Users/ADMIN/AppData/Local/Temp/claude/D--HK7-WAD-IA-IA-3/f51d859c-3a7f-4908-96b2-6c049f665f8d/scratchpad/review-input/brief.md
C:/Users/ADMIN/AppData/Local/Temp/claude/D--HK7-WAD-IA-IA-3/f51d859c-3a7f-4908-96b2-6c049f665f8d/scratchpad/review-input/a.js
C:/Users/ADMIN/AppData/Local/Temp/claude/D--HK7-WAD-IA-IA-3/f51d859c-3a7f-4908-96b2-6c049f665f8d/scratchpad/review-input/b.js
C:/Users/ADMIN/AppData/Local/Temp/claude/D--HK7-WAD-IA-IA-3/f51d859c-3a7f-4908-96b2-6c049f665f8d/scratchpad/review-input/c.js

An assistant was given brief.md three times and wrote a.js, b.js and c.js. Review each of the three files against brief.md. For each version, list every problem you find — a requirement of the brief it does not meet, a bug, or anything that would behave wrongly when the API is slow, fails, hangs or returns an empty list — with the line number(s) and what the user would see. Then give each version a verdict: keep, fix or reject. Do not rewrite the files. Answer in English, as your final message, in Markdown.
~~~~

## 2. Its answer, pasted unedited

~~~~markdown
# Review of a.js, b.js and c.js against brief.md

I read only the four files I was given and ran nothing. Everything below comes from reading the code against the brief.

## a.js: **Fix**

| Line(s) | Problem | What the user would see |
|---|---|---|
| 51–56 | **The stock value is always wrong (requirement 5).** `products.forEach(async …)` starts the stock requests but does not wait for them. Line 56 runs straight away, while `total` is still `0`. | `#stock-value` always shows `0 đ`, even when there are products with stock. The real total is added to `total` later, but nothing ever writes it to the page. |
| 52–55 | **Stock errors escape the `try/catch`.** A rejected `getStock` (a 404, a network error or bad JSON) happens inside a callback that nobody waits for, so the `catch` on line 57 never sees it. | The Console shows a red "Uncaught (in promise) Error: GET /api/stock/… failed", which breaks the "Console stays free of red errors" constraint. The page still shows `0 đ`, and there is no failure message. |
| 20 | No timeout on the stock requests (minor; the brief does not require one). | Nothing visible, because line 56 never waits for them anyway. |

Everything else meets the brief:
- The 5 s timeout works (line 14, `AbortSignal.timeout`).
- Non-2xx and network errors lead to `Could not load products.` and the Retry button.
- Retry hides the button and starts again.
- Cards are filled with `textContent`, and `data-id` and price formatting are correct.
- An empty list shows `No products yet.`, and the stock value is `0 đ` (correct only by accident).

Using `Promise.all` in lines 51–56 fixes both bugs.

## b.js: **Fix**

| Line(s) | Problem | What the user would see |
|---|---|---|
| 16 | **There is no timeout (requirement 4).** `fetch` has no `timeout` option, so `{ timeout: 5000 }` does nothing. The comment says it stops after 5 s, but it doesn't. | If the API never answers, `#status` says `Loading products…` forever, Retry never appears, and `loading` stays `true`. If the API is slow (over 5 s), the user waits as long as it takes instead of getting the error and Retry after 5 s. |
| 51, 54–56 | **A failed stock request is reported as a failed product load.** The cards are already on the page (line 47) and the status has been cleared (line 48). Then a stock rejection, for example a 404, goes to the shared `catch`. | The cards stay visible, yet `#status` says `Could not load products.` and Retry is shown, which contradicts what is on screen. `#stock-value` stays `—`. |
| 22 | No timeout on stock requests (minor). | If one stock call hangs, `#stock-value` shows `—` forever, with no message. |

Everything else is correct:
- The cards, `textContent`, formatting and order are right.
- An empty list shows `No products yet.` and `0 đ`.
- The stock requests run in parallel, and the total is correct.
- The list is cleared at the start of each attempt (line 42), so Retry does not duplicate cards.
- The status is cleared after the cards render.

Changing line 16 to `signal: AbortSignal.timeout(5000)` fixes the main bug.

## c.js: **Keep**

I found no bug against the brief:
- **Timeout:** the 5 s timeout works (line 16). Like any other failure, the `TimeoutError` is caught silently (lines 58–61), with no `console.error`.
- **Errors:** non-2xx and network errors lead to `Could not load products.` and Retry. Retry hides the button and restarts from step 1, and the `inFlight` guard prevents double loads.
- **Cards:** `textContent` is used everywhere. `data-id`, the `vi-VN` price format and the API order are correct.
- **Empty list:** it shows `No products yet.`, and `Promise.all([])` gives `0 đ`.
- **Stock:** the requests run in parallel, and the code waits for them before writing the total.

Minor points (not breaches of the brief):
- **Lines 54, 58–60:** a failed stock request removes cards that loaded successfully and shows `Could not load products.`. The brief doesn't say what should happen here, and the message is a little misleading, but the user gets a working Retry.
- **Line 22:** no timeout on stock requests. If one hangs, `#stock-value` stays `—` forever. The brief doesn't ask for a timeout here.

## Note for all three

When the server answers `500`, Chrome itself logs a red "GET /api/products 500" line in the Console. None of the files can stop that, and it is not a `console.error` from the code, so I did not count it against any version.

## Verdicts

| File | Verdict | Main reason |
|---|---|---|
| a.js | Fix | The stock value is always `0 đ`, and stock failures cause unhandled rejections that show as red errors in the Console. |
| b.js | Fix | The 5 s timeout does nothing, so a hanging API leaves the page on "Loading products…" forever with no Retry. |
| c.js | Keep | Meets every requirement. There are only minor issues in edge cases the brief does not cover. |
~~~~

## 3. Each claim, checked

"Row" = a row of *Done means* in `VERDICTS.md` / `evidence/run-original.txt`.
"Fault run" = `evidence/run-review-checks.txt`: the same page with
`GET /api/stock/cap` forced to answer `404`, because no row makes a stock
request fail (every id in `server.mjs` exists).

| # | Version | The assistant's claim | Checked by | Result |
|---|---|---|---|---|
| 1 | A | Lines 51–56: `forEach(async …)` is not awaited, `#stock-value` always shows `0 đ` | Row 2 | **Confirmed.** `0 đ` at 1.5 s while all 8 stock requests answered `200` (last at 930 ms); `evidence/a-row2.png` |
| 2 | A | Lines 52–55: a failed stock request escapes `try/catch` → red `Uncaught (in promise)` in the Console, page stays `0 đ`, no message | Row 7 + fault run | **Real, but no row shows it.** Row 7 passes with the real server (no stock request fails). Fault run: Console `Uncaught (in promise) Error: GET /api/stock/cap failed: HTTP 404 at getStock (a.js:21)`, page `0 đ`, no message, Retry hidden — exactly as claimed |
| 3 | A | Line 20: no timeout on stock requests (minor) | — | **Not a failure under any row.** The brief asks for a 5 s timeout on `/api/products` only; stock answers in 100–600 ms |
| 4 | A | The 5 s timeout works (line 14) | Row 6 | **Confirmed.** Gave up at 5099 ms; server: `the browser gave up after 5009 ms` |
| 5 | A | Non-2xx → message + Retry; Retry hides it and starts again | Row 5 | **Confirmed.** |
| 6 | A | `textContent`, `data-id`, price format correct | Rows 1, 3 | **Confirmed.** API order, `180.000 đ`, `Scarf <i>limited</i>` with 0 `<i>` |
| 7 | A | Empty list → `No products yet.`, `0 đ` "correct only by accident" | Empty row | **Confirmed.** |
| 8 | B | Line 16: `{ timeout: 5000 }` does nothing — a hanging API leaves `Loading products…` and no Retry **forever**; a slow API (> 5 s) is waited out | Row 6 (+ row 8) | **Confirmed, one overstatement.** Still `Loading products…` at 5.5, 7, 15 and 25 s; `products` pending (`evidence/b-row6.png`). Not *forever* with this server: its `504` at 30.01 s lands in `catch` and the message + Retry appear (`evidence/b-row6-at32s.png`). The row fails all the same — it asks for the message after about 5 s |
| 9 | B | Lines 51, 54–56: a failed stock request leaves the cards on screen while the status says `Could not load products.` and Retry shows; stock stays `—` | Fault run | **Real, but no row shows it.** Fault run: 8 cards, `Could not load products.`, Retry shown, `—`. The brief does not say what a stock failure should look like |
| 10 | B | Line 22: no timeout on stock requests (minor) | — | **Not a failure under any row** (as claim 3) |
| 11 | B | Cards, `textContent`, order, empty list, parallel stock and the total are correct; list cleared at line 42 | Rows 1–5, empty, parallel check | **Confirmed.** `12.360.000 đ`, stock requests started within 1 ms |
| 12 | C | No bug against the brief; timeout, errors, Retry, cards, empty list, parallel stock all correct | Rows 1–8, empty, parallel check | **Confirmed.** Every row passes (`evidence/run-original.txt`) |
| 13 | C | Lines 54, 58–60: a failed stock request removes the cards and shows `Could not load products.` (minor) | Fault run | **Real, but no row shows it.** Fault run: 0 cards, `Could not load products.`, Retry shown. Not a breach of the brief, as the assistant says |
| 14 | C | Line 22: no timeout on stock requests (minor) | — | **Not a failure under any row** |
| 15 | all | Chrome's own red `GET … 500` line is not the code's fault | Row 7 | **Confirmed.** It is the browser reporting the network; the same is true of the `favicon.ico 404` line it did not mention |

## 4. Failing rows the assistant missed

| Version | Row | What the assistant said | What the run showed |
|---|---|---|---|
| B | **Row 8** | Nothing about type checking. It found the cause (`fetch` has no `timeout` option) but never said `// @ts-check` would reject line 16 | `public/versions/b.js:17:51 - error TS2353: … 'timeout' does not exist in type 'RequestInit'`, exit code 2 (`evidence/b-row8.png`) |

Every other failing row (A row 2, B row 6) it found, with the right lines.

## 5. Where it was wrong

- **Missed:** B row 8, above.
- **Overstated:** B's hang lasts "forever". With the starter's server the
  page recovers after 30 s, when the `504` arrives. The row still fails.
- **Invented:** nothing. Its three stock-failure claims (2, 9, 13) are real
  behaviour, shown by the fault run, but no row of *Done means* tests a
  failing stock request, so none of them changes a verdict.
- Its verdicts — A fix, B fix, C keep — match mine.
