#!/usr/bin/env bash
# run: bash tests/test.sh
# exercises the two bits with real logic — the Stop-hook parser and `unc stats`.
# everything runs against a throwaway HOME so it never touches your real ~/.unc.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"

command -v jq >/dev/null || { echo "SKIP: tests need jq"; exit 0; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp"

pass=0
check() { if [ "$2" = "$3" ]; then pass=$((pass+1)); else echo "FAIL: $1 — want [$3] got [$2]"; exit 1; fi; }

# --- unc-bench: fake a repo + a transcript, run the hook, read the line ---
repo="$tmp/repo"; mkdir -p "$repo"; git -C "$repo" init -q
git -C "$repo" config user.email t@t; git -C "$repo" config user.name t
printf 'a\nb\n' > "$repo/f.txt"; git -C "$repo" add .; git -C "$repo" commit -qm init
printf 'a\nb\nc\nd\n' > "$repo/f.txt"   # +2 lines, uncommitted

tx="$tmp/tx.jsonl"
# second row carries cache reads — input must count those too, not just input_tokens
printf '%s\n' '{"message":{"usage":{"output_tokens":100,"input_tokens":500}}}' \
              '{"message":{"usage":{"output_tokens":40,"input_tokens":10,"cache_read_input_tokens":1000}}}' > "$tx"

printf '{"transcript_path":"%s","cwd":"%s"}' "$tx" "$repo" | bash "$ROOT/hooks/unc-bench.sh"

line="$(cat "$HOME/.unc/sessions.ndjson")"
check "out tokens summed" "$(jq -r .out_tokens <<<"$line")" "140"
check "in tokens + cache" "$(jq -r .in_tokens  <<<"$line")" "1510"
check "insertions"        "$(jq -r .insertions <<<"$line")" "2"

# --- unc stats: aggregate two known rows ---
cat > "$HOME/.unc/sessions.ndjson" <<'JSON'
{"ts":"x","cwd":"/a","out_tokens":100,"in_tokens":10,"files":1,"insertions":5,"deletions":1}
{"ts":"y","cwd":"/a","out_tokens":300,"in_tokens":20,"files":2,"insertions":5,"deletions":4}
JSON
out="$(bash "$ROOT/bin/unc" stats)"
check "session count" "$(grep -c '2 sessions' <<<"$out")" "1"
check "net loc"       "$(grep -oE 'net LOC +[0-9]+' <<<"$out" | grep -oE '[0-9]+' | head -1)" "5"
# out 400 -> caveman 742; in 30 -> codedb 7; total tokens 749. ins 10 -> ponytail 11 LOC
check "combined tokens" "$(grep -oE 'saved you ~[0-9]+ tokens' <<<"$out" | grep -oE '[0-9]+')" "749"
check "combined loc"    "$(grep -oE '\+ ~[0-9]+ LOC' <<<"$out" | grep -oE '[0-9]+')" "11"

# --- on/off toggle ---
bash "$ROOT/bin/unc" off >/dev/null; check "off writes flag" "$([ -f "$HOME/.unc/off" ] && echo y)" "y"
bash "$ROOT/bin/unc" on  >/dev/null; check "on clears flag"  "$([ -f "$HOME/.unc/off" ] || echo n)" "n"

echo "ok — $pass checks passed"