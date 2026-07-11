# unc

> the uncle who's been at the company longer than the version control. writes less code, says less, ships more. now he lives in your agent.

**unc** is a one-command loadout that makes your AI coding agent lazy in the good way: fewer tokens, less code, cheaper context. it doesn't reinvent anything, it just equips three tools that already work and binds them under one rule, then quietly tracks whether it actually paid off.

```bash
curl -fsSL https://raw.githubusercontent.com/0ss/unc/main/install.sh | bash
```

that's it. restart your agent and unc is on.

## what's in the loadout

unc orchestrates three great open-source tools. it does not vendor them, it installs them and keeps them fresh:

| tool | axis it cuts | who made it |
|------|-------------|-------------|
| [ponytail](https://github.com/DietrichGebert/ponytail) | code you write | @DietrichGebert |
| [caveman](https://github.com/JuliusBrussee/caveman) | words the agent says (output tokens) | @JuliusBrussee |
| [codedb](https://github.com/justrach/codedb) | context in (structured search vs grep dumps) | @justrach |

then unc adds two thin things of its own:

- **one rule**, injected every turn: *ponytail + caveman + codedb, always, silently.* no per-reply banner, it just holds.
- **a passive benchmark**: a Stop hook logs real numbers per turn (tokens from the transcript, code churn from git) so you can see the trend instead of guessing.

three tools + one rule + one number. nothing else. adding more would be the exact bloat unc exists to kill.

## the rule

every turn the agent gets nudged with this, and nothing more:

```
1. ponytail — laziest correct solution. reuse > stdlib > native > one line > minimum new code.
2. caveman  — terse output. code, commits, security still written normally.
3. codedb   — codedb_* tools for search/read/symbols, not grep/cat/find.
```

turn it off when you want the full lecture back:

```bash
unc off      # rule goes quiet (hooks stay installed)
unc on       # back on
```

## the benchmark

unc keeps its numbers honest. it logs what actually happened, it does not compare against a fake baseline and it does not call tracked tokens "saved" (no A/B, no saved claim).

```bash
$ unc stats
unc stats — 34 sessions
  output tokens   182304
  input tokens    2211890
  lines added     4120
  lines removed   3890
  net LOC         230
  avg out/session 5362
```

one json line per turn lands in `~/.unc/sessions.ndjson`. it's yours, it's local, nothing phones home.

want it on your statusline? unc won't clobber one you already have, so wire it yourself in `~/.claude/settings.json`:

```json
{ "statusLine": { "type": "command", "command": "~/.claude/hooks/unc-status.sh" } }
```

## commands

```
unc stats      what the benchmark has tracked
unc on | off   toggle the always-on rule
unc status     one-line status (for a statusline)
unc where      where unc keeps its files
```

## honest notes

- **caveman only cuts output tokens**, and adds a bit of input per turn. on already-terse work it can go net-negative. the real cost win comes from codedb (less context in) and ponytail (less code out). unc tracks all of it so you can see which is actually winning for you.
- **the benchmark is personal, not a proof.** it's your dashboard, not a reproducible study. if you want a rerunnable A/B, ponytail and caveman both ship one.
- **churn resets if you commit mid-session.** good enough for a trend, not exact per-turn accounting. see the note in `hooks/unc-bench.sh`.

## uninstall

```bash
bash ~/.unc/src/uninstall.sh            # removes unc's hooks + cli, keeps your log
bash ~/.unc/src/uninstall.sh --purge    # also deletes ~/.unc
```

the three tools have their own uninstallers, unc leaves them alone.

## dev

```bash
bash tests/test.sh
```

## license

MIT. built on the shoulders of ponytail, caveman, and codedb. go star those.
