# how unc counts your savings

Short version: `unc stats --how`. This is the long, auditable version — every
formula, every source, and an honest map of what unc *can* and *cannot* measure.

## the core honesty problem

You only ever do a task **once**, with the rule on. There is no parallel "you"
who did the *same task* with the rule off. So the counterfactual — what you'd
have written without unc — is unobservable for any given task.

ponytail's own `/ponytail-gain` command says this out loud:

> "NEVER print a per-repo savings number: the unbuilt version was never written,
> so there is no real baseline to subtract from in a live repo."

unc respects that. It never fabricates a per-task baseline. It only reports two
honest things: a **borrowed estimate**, or a **measured before/after** from real
on-vs-off sessions you actually logged.

## what unc logs

The `unc-bench.sh` Stop hook writes one JSON line per turn to
`~/.unc/sessions.ndjson`:

- `out_tokens` — output tokens for the turn (from the transcript usage).
- `in_tokens` — input **incl. cache reads** (context that got re-sent). Big, and
  ~10× cheaper per token than fresh output. Logged for visibility, **never
  counted as dollars saved.**
- `insertions` / `deletions` — `git diff --shortstat HEAD` churn.
- `rule` — `on` or `off` (from the `~/.unc/off` flag). This tag is what makes a
  before/after possible at all.

No network, no phone-home. The file is yours.

## the confidence ladder — the card wears its tier

### ① ESTIMATE (borrowed) — the default, and what most people see forever

Until you have enough `off` sessions (most people keep the rule on always), unc
combines each tool's **own published benchmark** — one tool per axis, so nothing
is counted twice:

```
output_tokens_saved = sum(out_tokens on-sessions) × 0.65 / 0.35   # caveman -65% output
lines_saved         = sum(lines on-sessions)      × 0.54 / 0.46   # ponytail -54% code
dollars_saved       = output_tokens_saved / 1e6 × UNC_PRICE       # output rate only
# codedb: leaner context in — no clean per-session %, so it's named, not summed
```

Why adding them is fair, not double-dipping: the three tools shrink **different
things** — caveman shrinks what the model *says* (output), ponytail shrinks what
it *writes* (code), codedb shrinks what it *reads* (context). No overlap.

- `-65%` is caveman's own measured output-token reduction (10 tasks, Claude API).
  It's applied only to **output** tokens — caveman's own documented domain.
- `-54%` is ponytail's median LOC reduction. Lines only.
- Labeled **"trust me bro"** on the card, because it assumes the rule caused the
  reduction. It can't prove that. It's an extrapolation, not a measurement.

### ② MEASURED (your data) — the one thing your logs can actually prove

Once you have ≥ `UNC_MIN_OFF` (default 3) `off` code-sessions, unc compares a
**rate** that is stable across task size:

```
rate            = out_tokens / insertions          # words per line of code, per code-session
on_rate         = median(rate over on-sessions)
off_rate        = median(rate over off-sessions)
saved_per_line  = max(0, off_rate − on_rate)
output_saved    = saved_per_line × (lines you shipped on-rule)
dollars_saved   = output_saved / 1e6 × UNC_PRICE
```

Why this and not per-session totals:

- **Normalized per line** → a big task vs a small one no longer skews it. Kills
  the "off-sessions were just bigger tasks" confound.
- **Median, not mean** → one giant session can't swing the number.
- **Code-sessions only** (`insertions > 0`) → chat-only turns don't pollute the
  rate.
- A **confidence word scales with sample size**: `preliminary` (n<8),
  `measured` (n<20), `solid` (n≥20). The card never claims more than n earns.

Honest caveat baked in: on-vs-off is **self-assigned, not randomized**, so this
is an *observational* before/after, not a controlled trial. Alternate on/off on
similar work for the fairest read.

## LINES saved is always a borrowed estimate — never "measured"

You cannot observe the lines you *didn't* write on a task you did once. So
"lines saved" is **always** ponytail's lab figure, and the card always tags it
`ponytail est`:

```
lines_saved_est = (lines you shipped) × 0.54 / 0.46
```

`-54%` is ponytail's median LOC reduction across 12 feature tasks. It is shown
for context, never dressed up as your own measurement.

## why $ is output-only

caveman's README is explicit: *"Caveman only affects output tokens —
thinking/reasoning untouched."* And input is dominated by cache reads (~10×
cheaper). Pricing anything but output would inflate the number. So:
`UNC_PRICE` is `$/Mtok` **output**, and only output tokens are ever monetized.

## why codedb is not in the number

codedb's win (fast, structured context retrieval) is **per query**, not per
session, and its CLI exposes no savings metric — only index `status`. Guessing a
per-session % would be a lie, so codedb contributes context quality, not a line
item. It shows up in the *measured* rate for free (leaner context → fewer tokens)
but is never separately claimed.

## the knobs

| env var | default | what |
|---|---|---|
| `UNC_PRICE` | `15` | output price, $/Mtok — set to your model's rate |
| `UNC_MIN_OFF` | `3` | off code-sessions before measured mode unlocks |

## primary sources

- **ponytail** — agentic benchmark: `-54%` LOC, `-22%` tokens, `-20%` cost,
  `-27%` time, 100% safe (Haiku 4.5, n=4, 12 feature tasks vs no-skill baseline).
  See `benchmarks/results/2026-06-18-agentic.md` in
  [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail). The
  earlier "80–94% less code" single-shot figure is a per-task ceiling, not a mean.
- **caveman** — `65%` mean output-token reduction across 10 tasks (Claude API,
  range 22–87%); `caveman-compress` ~`45%` input on CLAUDE.md files. Output-only
  by the author's own note. See
  [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) README.
- **codedb** — [justrach/codedb](https://github.com/justrach/codedb). Per-query
  retrieval tool; no per-session savings metric.

If a number here ever drifts from these sources, the sources win. Open an issue.
