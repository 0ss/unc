# unc 🦥

[![test](https://github.com/0ss/unc/actions/workflows/test.yml/badge.svg)](https://github.com/0ss/unc/actions/workflows/test.yml)

> the uncle who's been here longer than the version control. writes less code, says less, ships more. now he rides shotgun in your agent.

unc is a loadout, not a tool. one command equips your AI agent with three things that already work, binds them under one always-on rule, and keeps an honest receipt of what it saved you.

```bash
curl -fsSL https://raw.githubusercontent.com/0ss/unc/main/install.sh | bash
```

restart your agent. done. works with anything that reads a rule and lets a hook log a turn — **Claude, Codex, Cursor, Gemini**.

## the loadout

three tools that already work (unc installs them, never vendors them — they stay fresh) + one rule + one honest benchmark:

| tool | cuts | by |
|------|------|----|
| [ponytail](https://github.com/DietrichGebert/ponytail) | code you write | @DietrichGebert |
| [caveman](https://github.com/JuliusBrussee/caveman) | output tokens | @JuliusBrussee |
| [codedb](https://github.com/justrach/codedb) | context in | @justrach |

**the rule** (injected every turn, silent): `ponytail + caveman + codedb, always`.
**the benchmark**: a Stop hook logs real output tokens + git churn per turn. no phone-home, the file is yours.

## the receipt

```bash
unc stats --share
```

```
  🦥 unc wrapped  estimate

     280k output tokens saved   ~$4.20

     output   ██████░░░░  -65% · caveman
     code     █████░░░░░  -54% · ponytail est
     context  ██████████  codedb · leaner in

     12 sessions · 12 on / 0 off · math → unc stats --how
```

Screenshot it, post it. The number is always derived from **your** real logged usage — an empty log shows nothing, and the card always wears its tier so an estimate can never masquerade as proof.

## honest by design

unc will not lie to you, which is the whole point:

- **You only do each task once, rule-on** — so there's no true baseline to subtract. unc never invents one. (ponytail's own `/ponytail-gain` refuses to for the same reason.)
- **ESTIMATE** (what most people see forever): each tool's own published number on its own axis — caveman `-65%` output, ponytail `-54%` code, codedb leaner context — scaled to your real usage, labeled *trust me bro*. An extrapolation, not a measurement.
- **MEASURED** (if you ever run `unc off` a few times): words-per-line-of-code, rule-on vs rule-off, from your own logs. Median, normalized per line, confidence scales with sample size.
- **Lines saved** is *always* a ponytail lab estimate — you can't measure the lines you didn't write.
- **$ is output-only.** Cache reads are shown but never monetized (they're ~10× cheaper). Tune with `UNC_PRICE`.

Full formulas + sources: **[METHODOLOGY.md](METHODOLOGY.md)** or `unc stats --how`.

## use it

`unc` is a shell command, not something you type at your agent:

```bash
unc stats          # numbers + honest savings
unc stats --share  # the receipt card
unc stats --how    # how the numbers are calculated
unc on | off       # toggle the rule
unc status         # one-liner, for a statusline
```

## what it touches (and easy off)

unc is **hooks + a CLI, not a skill you add inside Claude.** The installer edits your global `~/.claude/settings.json` to register three hooks, drops them in `~/.claude/hooks/`, and puts `unc` on your PATH. That's it. Opting out is layered and easy:

```bash
unc off              # pause the rule (reversible; unc on to resume)
unc uninstall        # remove hooks + cli, keep your log
unc uninstall --purge  # also delete ~/.unc
```

## dev

```bash
bash tests/test.sh
```

MIT. built on ponytail, caveman, codedb — go star those.
