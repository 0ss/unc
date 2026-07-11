# how unc counts

Short version: `unc stats --how`. This is the auditable one.

## the honest problem
You do each task once, rule-on. There's no un-tooled version of the same task to
compare against — so a "savings" number is a **guesstimate**, not a measurement.
ponytail's own `/ponytail-gain` refuses to guess a per-repo number for this
reason. unc guesses from the tools' published benchmarks and labels it *trust me bro*.

## what it logs
A Stop hook appends one line per **turn** to `~/.unc/sessions.ndjson`: output
tokens, input (incl cache), git churn, codedb query count, a session id, and the
`on/off` rule tag. No network. Starts at install — nothing before it counts.

## the number
Rows are **cumulative** per session, so stats **de-dupes by session and takes the
max** (never sums rows — that 10×'d it). Then, one tool per axis (no overlap):

```
tokens saved = Σ(max output per session, rule-on) × 65/35   # caveman -65% output
lines saved  = Σ(max lines  per session, rule-on) × 54/46   # ponytail -54% code
$ saved      = tokens saved / 1e6 × UNC_PRICE               # OUTPUT tokens only
codedb saved = Σ(codedb queries) × UNC_CODEDB_PER_Q         # shown, NOT in $
```

- **Output-only $** — caveman only cuts output; input is mostly cache (~10× cheaper).
- **codedb** — each query replaces a grep + whole-file read (~1500 tokens, a knob).
  It's context, not dollars, so it's shown but never monetized.
- **measured mode** (if you ever run `unc off` enough): swaps the caveman guess for
  your own words-per-line on vs off. Most people stay in estimate forever.

## knobs
`UNC_PRICE` (output $/Mtok, def 15) · `UNC_CODEDB_PER_Q` (def 1500) · `UNC_MIN_OFF` (def 3).

## sources
- ponytail: −54% LOC, −22% tokens (agentic bench, Haiku 4.5) — [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail)
- caveman: −65% output tokens (10 tasks, Claude API) — [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman)
- codedb: per-query context retrieval, no per-session metric — [justrach/codedb](https://github.com/justrach/codedb)
