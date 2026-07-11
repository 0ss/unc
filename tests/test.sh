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
# no off-sessions -> SEED. (400*.65/.35 + 30*.25) floored = 750. ins 10 -> 11 LOC
check "seed mode"       "$(grep -c 'trust me bro' <<<"$out")" "1"
check "seed tokens"     "$(grep -oE 'reckons ~[0-9]+ tokens' <<<"$out" | grep -oE '[0-9]+')" "750"
check "seed loc"        "$(grep -oE '\+ ~[0-9]+ LOC' <<<"$out" | grep -oE '[0-9]+')" "11"

# --- measured mode: 2 on-rows vs 3 off-rows, real A/B ---
# on out mean 100, off out mean 300 -> per-session save 200 * 2 on = 400 tokens
# off insertions mean 10, on 0 -> 10 * 2 = 20 LOC
cat > "$HOME/.unc/sessions.ndjson" <<'JSON'
{"rule":"on","out_tokens":100,"in_tokens":0,"insertions":0,"deletions":0}
{"rule":"on","out_tokens":100,"in_tokens":0,"insertions":0,"deletions":0}
{"rule":"off","out_tokens":300,"in_tokens":0,"insertions":10,"deletions":0}
{"rule":"off","out_tokens":300,"in_tokens":0,"insertions":10,"deletions":0}
{"rule":"off","out_tokens":300,"in_tokens":0,"insertions":10,"deletions":0}
JSON
m="$(bash "$ROOT/bin/unc" stats)"
check "measured mode"   "$(grep -c 'MEASURED' <<<"$m")" "1"
check "measured tokens" "$(grep -oE 'MEASURED ~[0-9]+ tokens' <<<"$m" | grep -oE '[0-9]+')" "400"
check "measured loc"    "$(grep -oE '\+ ~[0-9]+ LOC' <<<"$m" | grep -oE '[0-9]+')" "20"

# --- on/off toggle ---
bash "$ROOT/bin/unc" off >/dev/null; check "off writes flag" "$([ -f "$HOME/.unc/off" ] && echo y)" "y"
bash "$ROOT/bin/unc" on  >/dev/null; check "on clears flag"  "$([ -f "$HOME/.unc/off" ] || echo n)" "n"

echo "ok — $pass checks passed"