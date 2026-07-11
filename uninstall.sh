#!/usr/bin/env bash
# unc uninstaller — removes unc's hooks + CLI. Leaves the three tools alone
# (uninstall those with their own uninstallers) and keeps your ~/.unc log
# unless you pass --purge.
set -euo pipefail
SETTINGS="$HOME/.claude/settings.json"
HOOKS="$HOME/.claude/hooks"

if command -v python3 >/dev/null 2>&1 && [ -f "$SETTINGS" ]; then
  python3 - "$SETTINGS" <<'PY'
import json, sys
p = sys.argv[1]
cfg = json.load(open(p))
for event, entries in cfg.get("hooks", {}).items():
    cfg["hooks"][event] = [e for e in entries
        if "unc-rule.sh" not in json.dumps(e) and "unc-bench.sh" not in json.dumps(e)]
json.dump(cfg, open(p, "w"), indent=2)
print("unregistered unc hooks from settings.json")
PY
fi

rm -f "$HOOKS/unc-rule.sh" "$HOOKS/unc-bench.sh" "$HOOKS/unc-status.sh"
for d in "$HOME/.local/bin" "/usr/local/bin"; do rm -f "$d/unc" 2>/dev/null || true; done
echo "removed unc hooks + cli"

if [ "${1:-}" = "--purge" ]; then rm -rf "$HOME/.unc"; echo "purged ~/.unc (log + src)"; else
  echo "kept your benchmark log at ~/.unc (pass --purge to delete)"; fi