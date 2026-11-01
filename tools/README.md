# tools/ — the scripts behind `evidence/`

Copies of the scripts Claude Code wrote and ran for this assignment, so every
number and screenshot in `evidence/` can be traced to the code that produced
it. They ran from `D:\HK7\WAD\IA\IA#3\tools\` — one level above this repo — and
were copied here unchanged on 2026-10-30, so paths inside them assume that
location. None of
them is loaded by the page; nothing in `public/` uses them.

| Script | Used for | Output |
|---|---|---|
| `harness.js` | rows 1–7, empty, parallel check — pasted into the page at `http://localhost:5050/`; drives `/?v=<letter>` in an iframe and switches modes with `POST /__mode` like the Test conditions buttons. The `until`/`snap` guard and the 1.5 s row-4 wait were added on 2026-10-30 (see AI-LOG) | `evidence/run-original.txt`, `evidence/run-after-fixes.txt` |
| `fault-stock.js` | forces `/api/stock/cap` to answer 404 inside the page's `fetch` | `evidence/run-review-checks.txt` (first set) |
| `shot.ps1` + `cdp-nav.mjs` | opens a separate Chrome (throwaway profile) with DevTools on Network, loads a URL, photographs the window; `-NoJs` blocks JavaScript, `-ScrollY` scrolls a view-source page | `csr-*.png` (its first `a-row2` / `b-row6` pictures were replaced by my own on 2026-10-31) |
| `csr-shots.ps1`, `source-shots.ps1` | run `shot.ps1` for the CSR vs SSR pictures | `csr-requests-*.png`, `csr-nojs-*.png`, `csr-source-*.png` (incl. `csr-source-ssr-scarf.png`, `-ScrollY 540`) |
| `row8-shot.ps1` + `row8-run.ps1` | adds `// @ts-check` to `b.js`, runs `tsc` in a real PowerShell window, photographs it, restores `b.js` | `b-row8-tsc.png` |
| `open-for-user.ps1` | opens Chrome (A in `normal`, B in `hang`, DevTools on Network) and VS Code on the untouched starter copy, for the screenshots I took by hand — it captures nothing | `a-row2.png`, `b-row6*.png`, `b-row8.png` (taken by me) |
| `row8-vscode.ps1` | the attempted VS Code version of row 8 — abandoned (sign-in screen); kept for honesty | none used |

The hang runs in the second set of `run-review-checks.txt` were typed into the
page directly (they load the original source from `git show 3676f2f:…` as a
blob module); their code is quoted in that file's description.
