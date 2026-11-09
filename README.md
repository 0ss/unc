# unc 🦥

[![test](https://github.com/0ss/unc/actions/workflows/test.yml/badge.svg)](https://github.com/0ss/unc/actions/workflows/test.yml)

> writes less code, says less, ships more.

Makes your agent write less and say less. One install.

```bash
curl -fsSL https://raw.githubusercontent.com/0ss/unc/main/install.sh | bash
```

Restart your agent. Done. Works with anything that reads a rule and lets a hook log a turn — **Claude, Codex, Cursor, Gemini**.

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
   🦥  unc wrapped   estimate

   280k   output tokens saved   ~$4.20

   output   ██████░░░░  -65% caveman
   code     █████░░░░░  -54% ponytail est
   context  ██████████  codedb 12 queries · ~18k not read

   34 turns · trust me bro · github.com/0ss/unc
```

Warm truecolor in a real terminal. The number is always derived from **your** real logged usage — an empty log shows nothing, and the card always wears its tier so an estimate can never masquerade as proof.

## honest by design

The number comes from **your** real logs — never a made-up baseline. Until you run `unc off` a few times it's a labeled estimate (*trust me bro*), and the card always says which. Full formulas + sources: **[METHODOLOGY.md](METHODOLOGY.md)**.

## use it

`unc` is a shell command, not something you type at your agent:

```bash
unc stats          # numbers + honest savings
unc stats --share  # the receipt card
unc on | off       # toggle the rule
unc status         # one-liner, for a statusline
unc uninstall      # remove unc (keeps your log)
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
