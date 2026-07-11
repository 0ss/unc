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
noansi() { sed $'s/\x1b\\[[0-9;]*m//g'; }   # strip color so greps see plain text

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
out="$(bash "$ROOT/bin/unc" stats | noansi)"
check "session count" "$(grep -c '2 sessions' <<<"$out")" "1"
check "net loc"       "$(grep -oE 'net LOC +[0-9]+' <<<"$out" | grep -oE '[0-9]+' | head -1)" "5"
# no off-sessions -> ESTIMATE (seed). output tokens: caveman 400*.65/.35 floored = 742.
# lines est: ponytail ins 10 * .54/.46 floored = 11 (always est, never "measured")
check "seed mode"       "$(grep -c 'trust me bro' <<<"$out")" "1"
check "seed tokens"     "$(grep -oE 'reckons ~[0-9]+ output tokens' <<<"$out" | grep -oE '[0-9]+')" "742"
check "seed loc est"    "$(grep -oE 'lines saved     ~[0-9]+' <<<"$out" | grep -oE '[0-9]+')" "11"

# --- measured mode: words-per-line rate, on vs off, median, output-only ---
# on rate = out/ins = 50/10 = 5 (x2). off rate = 100/10 = 10 (x3).
# median off 10 - median on 5 = 5 saved/line. on lines shipped = 20. tok = 5*20 = 100.
# lines saved stays a ponytail est: 20 * .54/.46 = 23.
cat > "$HOME/.unc/sessions.ndjson" <<'JSON'
{"rule":"on","out_tokens":50,"in_tokens":0,"insertions":10,"deletions":0}
{"rule":"on","out_tokens":50,"in_tokens":0,"insertions":10,"deletions":0}
{"rule":"off","out_tokens":100,"in_tokens":0,"insertions":10,"deletions":0}
{"rule":"off","out_tokens":100,"in_tokens":0,"insertions":10,"deletions":0}
{"rule":"off","out_tokens":100,"in_tokens":0,"insertions":10,"deletions":0}
JSON
m="$(bash "$ROOT/bin/unc" stats | noansi)"
check "measured mode"   "$(grep -c 'MEASURED' <<<"$m")" "1"
check "measured tokens" "$(grep -oE 'MEASURED ~[0-9]+ output tokens' <<<"$m" | grep -oE '[0-9]+')" "100"
check "measured loc est" "$(grep -oE 'lines saved     ~[0-9]+' <<<"$m" | grep -oE '[0-9]+')" "23"
check "measured rate"   "$(grep -c 'rule-on 5 vs off 10' <<<"$m")" "1"

# --- share card: wears its tier, shows honest labels ---
sc="$(bash "$ROOT/bin/unc" stats --share | noansi)"
check "share card"     "$(grep -c 'unc wrapped' <<<"$sc")" "1"
check "share tokens"   "$(grep 'output tokens saved' <<<"$sc" | grep -oE '[0-9]+' | head -1)" "100"
check "share loc est"  "$(grep -c 'ponytail est' <<<"$sc")" "1"

# --- --how prints methodology, no crash on empty-ish ---
check "how link" "$(bash "$ROOT/bin/unc" stats --how | grep -c 'METHODOLOGY.md')" "1"

# --- on/off toggle ---
bash "$ROOT/bin/unc" off >/dev/null; check "off writes flag" "$([ -f "$HOME/.unc/off" ] && echo y)" "y"
bash "$ROOT/bin/unc" on  >/dev/null; check "on clears flag"  "$([ -f "$HOME/.unc/off" ] || echo n)" "n"

echo "ok — $pass checks passed"