#!/usr/bin/env bash
# the one rule. whatever this prints gets glued into the agent's context.
# `unc off` writes the flag and we go quiet.

[ -f "$HOME/.unc/off" ] && exit 0

cat <<'RULE'
unc is on. Three habits — always, silently, no banner. Applies to this task and every subagent you spawn:

1. ponytail — laziest correct solution. Climb the ladder: reuse what exists > stdlib > native platform feature > installed dep > one line > minimum new code. No speculative abstractions, no scaffolding "for later". Understand the problem and read the code the change touches BEFORE picking a rung. Never lazy about validation, error handling, security, or accessibility.
2. caveman — terse output. Drop filler, hedging, pleasantries; fragments fine. Code, commits, and security notes are written normally.
3. codedb — reach for codedb_* MCP tools (search, symbol, outline, callers, deps, read, tree) instead of grep/cat/find/ripgrep. Fall back to native tools only when codedb has no index or cannot answer.
RULE