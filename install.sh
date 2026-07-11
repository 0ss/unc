#!/usr/bin/env bash
# curl -fsSL https://raw.githubusercontent.com/0ss/unc/main/install.sh | bash
# gets the three tools, drops unc's hooks, puts `unc` on PATH.
# safe to re-run: merges settings, never clobbers.

set -euo pipefail

REPO="https://github.com/0ss/unc"
RAW="https://raw.githubusercontent.com/0ss/unc/main"
CLAUDE_DIR="$HOME/.claude"
HOOKS_DST="$CLAUDE_DIR/hooks"
SETTINGS="$CLAUDE_DIR/settings.json"

say()  { printf '  %s\n' "$*"; }
head() { printf '\n\033[1m%s\033[0m\n' "$*"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }

head "unc — the lazy senior dev, equipped"

# ---- 0. locate source (local checkout, or clone) --------------------------
SRC=""
_self="${BASH_SOURCE[0]:-}"   # empty when piped through curl | bash
if [ -n "$_self" ] && [ -f "$(dirname "$_self")/hooks/unc-rule.sh" ]; then
  SRC="$(cd "$(dirname "$_self")" && pwd)"
else
  SRC="$HOME/.unc/src"
  head "fetching unc"
  if [ -d "$SRC/.git" ]; then git -C "$SRC" pull --quiet && ok "updated $SRC"
  else git clone --quiet "$REPO" "$SRC" && ok "cloned → $SRC"; fi
fi

# ---- 1. orchestrate the three tools ---------------------------------------
head "tools"
if command -v codedb >/dev/null 2>&1; then ok "codedb present ($(codedb --version 2>/dev/null))"
else say "installing codedb…"; curl -fsSL https://codedb.codegraff.com/install.sh | bash && ok "codedb"; fi

if [ -d "$HOME/.claude/skills/caveman" ] || [ -f "$HOME/.claude/.caveman-active" ]; then ok "caveman present"
else say "installing caveman…"; curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash && ok "caveman"; fi

if grep -q '"ponytail@ponytail"' "$SETTINGS" 2>/dev/null; then ok "ponytail present"
else
  say "ponytail is a Claude plugin — paste these two lines in Claude Code:"
  say "    /plugin marketplace add DietrichGebert/ponytail"
  say "    /plugin install ponytail@ponytail"
fi

# ---- 2. install unc hooks --------------------------------------------------
head "hooks"
mkdir -p "$HOOKS_DST" "$HOME/.unc"
for h in unc-rule unc-bench unc-status; do
  cp "$SRC/hooks/$h.sh" "$HOOKS_DST/$h.sh"
  chmod +x "$HOOKS_DST/$h.sh"
done
ok "copied unc-rule, unc-bench, unc-status → $HOOKS_DST"

# merge into settings.json without clobbering (needs python3)
if command -v python3 >/dev/null 2>&1; then
  python3 - "$SETTINGS" "$HOOKS_DST" <<'PY'
import json, os, sys
settings_path, hooks = sys.argv[1], sys.argv[2]
try:
    with open(settings_path) as f: cfg = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    cfg = {}
cfg.setdefault("hooks", {})

def ensure(event, script):
    entries = cfg["hooks"].setdefault(event, [])
    if any(script in json.dumps(e) for e in entries):
        return
    entries.append({"hooks": [{"type": "command",
                               "command": f"{hooks}/{script}"}]})

ensure("UserPromptSubmit", "unc-rule.sh")
ensure("SessionStart",     "unc-rule.sh")
ensure("Stop",             "unc-bench.sh")

os.makedirs(os.path.dirname(settings_path), exist_ok=True)
with open(settings_path, "w") as f:
    json.dump(cfg, f, indent=2)
print("  \033[32m✓\033[0m registered rule (UserPromptSubmit+SessionStart) + benchmark (Stop)")
PY
else
  say "python3 not found — add these to $SETTINGS hooks yourself:"
  say "  UserPromptSubmit + SessionStart → $HOOKS_DST/unc-rule.sh"
  say "  Stop → $HOOKS_DST/unc-bench.sh"
fi

# ---- 3. put `unc` on PATH --------------------------------------------------
head "cli"
BIN_DST=""
for d in "$HOME/.local/bin" "/usr/local/bin"; do
  if [ -d "$d" ] && [ -w "$d" ]; then BIN_DST="$d"; break; fi
done
[ -z "$BIN_DST" ] && { mkdir -p "$HOME/.local/bin"; BIN_DST="$HOME/.local/bin"; }
ln -sf "$SRC/bin/unc" "$BIN_DST/unc"
chmod +x "$SRC/bin/unc"
ok "unc → $BIN_DST/unc"
case ":$PATH:" in *":$BIN_DST:"*) ;; *) say "add to PATH: export PATH=\"$BIN_DST:\$PATH\"";; esac

head "done. unc is on."
say "restart Claude, then: unc stats"