# changelog

notable changes. newest on top.

## unreleased
- `unc stats --share` — Wrapped-style receipt card, wears its confidence tier
- reworked savings math, grounded in each tool's own benchmark, one per axis:
  - estimate = caveman -65% output + ponytail -54% code + codedb context (named)
  - no double-count (output vs code vs context don't overlap); labeled guesstimate
  - measured = words-per-line-of-code on vs off, median, output-only $
  - $ priced on output tokens only, never cache reads
- `unc stats --how` + METHODOLOGY.md — full formulas + primary sources
- `unc uninstall` shortcut
- readme repositioned as a loadout; install-is-hooks + easy opt-out documented

## 0.1.0
- first release: install ponytail + caveman + codedb under one always-on rule
- Stop-hook benchmark logs tokens + git churn per turn, tagged on/off
- `unc` CLI: stats / on / off / status / where / version
- self-calibrating savings: seed estimate → measured A/B once you have off-sessions
- CI, tests, MIT
