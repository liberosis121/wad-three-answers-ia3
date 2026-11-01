# Self-assessment — IA#3

Submitted by: 23120193 — Trần Kim Yến

Total I claim: 100 / 100

| Criterion | Max | I claim | Evidence |
|---|---|---|---|
| 1. Verdicts and evidence | 30 | 30 | `VERDICTS.md` §2: 9 rows × 3 versions, each PASS/FAIL with the number seen; FAILs A row 2, B rows 6 and 8 with the lines responsible (`a.js` 51–56, `b.js` 16), the verdict and its deciding row, and one sentence naming row, evidence and constraint (stock requests kept parallel). Predictions committed in `63951a7`, before the results in `9876e10`, and unchanged since. Screenshots I took myself of the page with DevTools / VS Code on the original code: `evidence/a-row2.png`, `evidence/b-row6.png` (still `Loading products…` at 7948 ms, `products` pending) + `b-row6-at30s.png` (`products` 504 after 30.01 s), `evidence/b-row8.png` (Problems: TS2353, Ln 17 Col 51) |
| 2. Every version passes every row | 25 | 25 | `evidence/run-after-fixes.txt`: A, B, C pass rows 1–8 and empty; 8 stock requests start within 1–2 ms (no staircase); `tsc` with `// @ts-check` exits 0 on all three. Fixes `3385d84` (`a.js`) and `274e790` (`b.js`); C kept untouched |
| 3. The assistant's review, checked | 15 | 15 | `ASSISTANT-REVIEW.md`: tool and model, a fresh isolated subagent, prompt and answer pasted unedited; all 15 claims checked by a row, the 404 fault run or the hang runs (`evidence/run-review-checks.txt`); the missed row (B row 8) and the overstatement ("forever" vs the 504 at 30.01 s) stated |
| 4. CSR vs SSR | 10 | 10 | `CSR-SSR.md`: View source `evidence/csr-source-c.png` / `csr-source-ssr.png`; JavaScript off `csr-nojs-*.png`; requests counted 3 vs 15 (2 vs 14 without favicon) in `csr-requests-*.png`; `&lt;i&gt;` from `escapeHtml` (`server.mjs:81`) matched against the scarf's `innerHTML` when filled with `textContent` |
| 5. AI-LOG.md | 10 | 10 | `AI-LOG.md`: one entry per use with time and commit, including the rejected first attempt; Changed/Rejected record real mistakes and what caught them — the review missed B row 8 (row 8), "forever" (row 6 at 30.01 s), a claim written before it was run (fault run), the row 4 harness timing, broken screenshots retaken |
| 6. Scope and commit history | 10 | 10 | `3676f2f` untouched starter first; `63951a7` predictions before `9876e10` results; `3385d84` touches only `a.js`, `274e790` only `b.js`; `git diff 3676f2f HEAD` changes no starter file other than `public/versions/a.js` and `b.js` (new files only: docs, `evidence/`, `tools/`) |

## What I did not manage

The 27 rows were measured by a script (`tools/harness.js`) that drives the real
page; I looked at the failing rows myself in Chrome and VS Code when I took the
screenshots, and they matched. A VS Code picture taken by a script did not work
(a fresh VS Code opened on its sign-in screen), so I took that one by hand.

## What I would do differently

Write each AI-LOG entry in the same commit as the work it describes, so no
entry has to ride with a later commit.
