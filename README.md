# unc

> the uncle who's been here longer than the version control. writes less code, says less, ships more. now he lives in your agent.

one command equips your AI agent with three tools that already work, binds them under one rule, and quietly tracks whether it paid off.

```bash
curl -fsSL https://raw.githubusercontent.com/0ss/unc/main/install.sh | bash
```

restart your agent. done.

## the loadout

unc installs these (doesn't vendor them — keeps them fresh) and adds one rule + one benchmark:

| tool | cuts | by |
|------|------|----|
| [ponytail](https://github.com/DietrichGebert/ponytail) | code you write | @DietrichGebert |
| [caveman](https://github.com/JuliusBrussee/caveman) | output tokens | @JuliusBrussee |
| [codedb](https://github.com/justrach/codedb) | context in | @justrach |

**the rule** (injected every turn, silent): `ponytail + caveman + codedb, always`.
**the benchmark**: a Stop hook logs real tokens + git churn per turn. no phone-home, it's yours.

## use it

`unc` is a shell command, not something you type at your agent:

```bash
unc stats      # what it tracked + estimated savings
unc on | off   # toggle the rule
unc status     # one-liner, for a statusline
```

```
🦥 unc saved you ~11k output tokens (est.) · ~$0.18
unc stats — 6 sessions
  output tokens   6347
  net LOC         230
```

## honest notes

- **"saved" is an estimate** (caveman's 65% output cut vs a verbose baseline), not a proof. tune the price with `UNC_PRICE` ($/Mtok output).
- **caveman only cuts output** and adds a little input; the real wins are codedb (context) + ponytail (code).
- **churn resets on mid-session commits.** fine for a trend. see `hooks/unc-bench.sh`.

## uninstall

```bash
bash ~/.unc/src/uninstall.sh          # keeps your log
bash ~/.unc/src/uninstall.sh --purge  # nukes ~/.unc too
```

## dev

```bash
bash tests/test.sh
```

MIT. built on ponytail, caveman, codedb — go star those.
