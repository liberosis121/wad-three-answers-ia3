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
- **Commit:** predictions (this entry).
