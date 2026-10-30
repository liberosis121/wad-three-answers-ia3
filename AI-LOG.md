# AI-LOG.md — IA#3 Three answers to one brief

**Student:** 23120193 — Trần Kim Yến

One entry per stage where an assistant did part of the work. Times are local
(UTC+7) and match the commit each entry ends with.

**Second pass.** A first attempt on 2026-10-29 (20:47–20:58) was discarded:
its evidence screenshots had a DevTools-style panel injected into the page
instead of real DevTools, and its log claimed a prediction change that the
prediction commit does not contain. That folder is kept outside the
submission. Everything below is the second pass, started from the untouched
starter.

---

## 2026-10-29 22:23 — Review of the first attempt, plan, starter commit
- **Tool:** Claude Code (desktop app), model Claude Opus 5.5.
- **Asked for:** check the first attempt against the rubric without changing
  anything, then a plan and a list of ready-to-send prompts for a clean redo.
- **Kept:** the plan (one commit per stage, fixes touching only their version
  file), the prompts, and the predictions it drafted from reading the code.
- **Changed:** —
- **Rejected:** the first attempt as a whole (fake DevTools panels in
  `evidence/`, a log contradicted by `git log`).
- **By hand:** chose to redo rather than patch; agreed to the four setup
  decisions (back up the first attempt, disclose it here, take the review
  from a fresh assistant, keep my git identity).
- **Commit:** `3676f2f` starter (the untouched starter, before anything else).

---

## 2026-10-29 22:24 — Predictions from reading
- **Tool:** Claude Code, Claude Opus 5.5.
- **Asked for:** predictions for A, B and C from reading the three files
  beside `brief.md`, with no run. Drafted during planning, before the starter
  commit, which is why this commit follows it within a minute.
- **Kept:** all of it, copied word for word into section 1 of `VERDICTS.md`:
  A fix (row 2, `forEach(async …)`), B fix (row 6, `{ timeout: 5000 }`; row 8
  probably), C keep. Two open doubts are written down rather than resolved
  (A's detached promises and row 7; `firstElementChild` and row 8).
- **Changed:** —
- **Rejected:** —
- **By hand:** read the draft and approved it before anything was run.
- **Commit:** `63951a7` predictions.

---

## 2026-10-29 22:26–23:01 — Running the table on the originals, screenshots
- **Tool:** Claude Code, Claude Opus 5.5.
- **Asked for:** start `node server.mjs` on 5050 in a terminal I could
  watch, run rows 1–8, empty and the parallel check on the three original
  files, log the numbers, then take the screenshots of the failing rows.
- **Kept:** the run (`evidence/run-original.txt`): A fails row 2, B fails
  rows 6 and 8, C passes everything — as predicted. Its harness drives the
  real page in an iframe and switches modes through `POST /__mode`; it lives
  in `tools/` outside the repo so nothing but `public/versions/*.js` is ever
  touched.
- **Changed:** I first opened Chrome to take the screenshots myself and got a
  red `favicon.ico 404` in the Console; Claude explained it is the browser's
  own request, not the page (now noted under row 7), and that `a-row2` needs
  the Network panel, not Console. I then asked it to take the screenshots
  itself. It wrote a script that opens a separate Chrome (throwaway profile)
  with DevTools docked on Network and photographs that window, and a second
  one that adds `// @ts-check` to `b.js`, runs `tsc` in a real PowerShell
  window, photographs it and restores `b.js` with `git checkout`. Its first
  captures were cut off (125 % display scaling) and showed `đ` garbled; both
  fixed and retaken. When I asked whether the screenshots would pass a strict
  grader, it judged `b-row6.png` alone shows no elapsed time and added
  `b-row6-at32s.png` (`products` 504 after 30.01 s).
- **Rejected:** —
- **By hand:** decided to let the assistant take the screenshots, asked for
  each image to be checked against the rubric, chose to keep the extra 32 s
  screenshot, confirmed the verdicts A fix, B fix, C keep and the two
  sentences.
- **Commit:** `9876e10` results.

---

## 2026-10-29 23:04–23:07 — The assistant's review, checked
- **Tool:** Claude Code; the review itself by a fresh `general-purpose`
  subagent (Claude Opus 5.5, no history), checking by the main session.
- **Asked for:** a review of the three ORIGINAL files against `brief.md`,
  with no verdict given. The subagent could read only a temp folder with
  those four files; prompt and answer are in `ASSISTANT-REVIEW.md`, unedited.
- **Kept:** its findings that match rows: A row 2 (`forEach(async …)`),
  B row 6 (`{ timeout: 5000 }`), C keep.
- **Changed:** its claim that B hangs "forever" — row 6's run shows the
  server's `504` at 30.01 s ends the wait (`b-row6-at32s.png`); the row
  fails anyway.
- **Rejected:** — no invented bug. Three claims about a failing stock
  request (A unhandled rejection, B cards + error message, C cards removed)
  are not tested by any row, so I had them checked by a fault run instead
  of by reading: `/api/stock/cap` forced to `404` in the page's `fetch`
  (`evidence/run-review-checks.txt`). All three are real; none changes a
  verdict.
- **What it got wrong:** it missed B row 8 (TS2353), which `evidence/b-row8.png`
  shows.
- **By hand:** asked for the review to be isolated from my verdicts and for
  every claim to be checked by a row or a run.
- **Commit:** `9612641` assistant review.

---

## 2026-10-30 22:21 — Fix A
- **Tool:** Claude Code, Claude Opus 5.5.
- **Asked for:** my one sentence for A from `VERDICTS.md` (row 2, `0 đ`,
  `forEach(async …)` on lines 52–55; wait for every stock response, keep the
  eight requests parallel, no `await` in a loop, change nothing else), then
  the whole table, the parallel check and `tsc`, and the diff before any
  commit.
- **Kept:** the 5 lines replaced by 2: `await Promise.all(products.map(…))`
  and a `reduce` for the total. Rerun: row 2 `12.360.000 đ`, every other row
  still passes, 8 stock requests start within 1 ms, `tsc` exit 0.
- **Changed:** — (it changed exactly what the sentence asked).
- **Rejected:** —
- **By hand:** read the diff (only `a.js`, 2 + / 5 −) and approved the commit.
- **Commit:** `3385d84` fix A (the commit holds only `a.js`; this entry
  rides with the rerun commit below).

---

## 2026-10-30 22:23 — Fix B
- **Tool:** Claude Code, Claude Opus 5.5.
- **Asked for:** my one sentence for B (rows 6 and 8, `{ timeout: 5000 }` on
  line 16; give up after 5 s so `catch` shows the message and Retry, keep the
  stock requests parallel, change nothing else), then the whole table and
  `tsc`, and the diff.
- **Kept:** the one-line change to `{ signal: AbortSignal.timeout(5000) }`.
  Rerun: row 6 message + Retry at 5038 ms, `tsc` exit 0, stock parallel.
- **Changed:** the first rerun showed `—` in the stock value in row 4, read
  0.8 s after the cards. The assistant measured it 5 times on A, B and C:
  the slowest stock answer lands 520–830 ms after the cards and the value is
  always `12.360.000 đ`. A timing gap in the harness, not the fix; the final
  rerun reads row 4 after 1.5 s.
- **Rejected:** —
- **By hand:** read the diff (only `b.js`, 1 line) and approved the commit.
- **Commit:** `274e790` fix B (only `b.js`; entry rides with the rerun).

---

## 2026-10-30 22:27 — The whole table again, after the fixes
- **Tool:** Claude Code, Claude Opus 5.5.
- **Asked for:** rows 1–8, empty and the parallel check on the final three
  files, saved to `evidence/run-after-fixes.txt`, and an "After fixes" table
  in `VERDICTS.md`.
- **Kept:** all three versions pass every row; stock requests start within
  1–2 ms; only `a.js` and `b.js` differ from the starter.
- **Changed:** the harness crashed once, reading the page before the iframe
  had a `#status` (its own bug, fixed with a guard). The assistant first
  wrote in `VERDICTS.md` that fix A also removes the `Uncaught (in promise)`
  without having run it; it then ran the stock-404 fault on fixed A (message
  + Retry, no page error) and cited that run.
- **Rejected:** —
- **By hand:** asked for the full rerun rather than the two fixed rows only.
- **Commit:** `7a87a98` rerun after fixes.

---

## 2026-10-30 22:41 — CSR vs SSR
- **Tool:** Claude Code, Claude Opus 5.5.
- **Asked for:** the four screenshots (requests on `/ssr` and `/?v=c`, both
  pages with JavaScript off), the real source of both pages, and answers to
  the README's five questions from what those show.
- **Kept:** the counts read off the Network bar — `/ssr` 3 requests (2
  without `favicon.ico`), `/?v=c` 15 (14) — and the JavaScript-off result:
  `/ssr` complete, `/?v=c` an empty shell with `Server mode: unknown` and
  only 3 requests, `panel.js` never fetched.
- **Changed:** I asked it to take these screenshots too. It extended the
  capture script with a `-NoJs` switch (Chrome site setting "JavaScript:
  Don't allow" in the throwaway profile) rather than pressing keys in
  DevTools. For question 2 it did not stop at the definition: it read the
  scarf's `<h2>` on `/?v=c` and found `innerHTML` = `Scarf &lt;i&gt;limited&lt;/i&gt;`,
  a single text node — the same text `/ssr` sends.
- **Rejected:** —
- **By hand:** asked for every answer to point at a screenshot, the source
  or a number, and read the five answers.
- **Commit:** CSR vs SSR (this entry).
