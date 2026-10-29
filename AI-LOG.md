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
- **Commit:** assistant review (this entry).
