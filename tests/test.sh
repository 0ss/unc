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

# --- unc stats: rows are CUMULATIVE per session; stats must take max, not sum ---
# one session, two cumulative turns: out grows 100->300, ins 3->5. take the max.
cat > "$HOME/.unc/sessions.ndjson" <<'JSON'
{"session":"s1","cwd":"/a","rule":"on","out_tokens":100,"in_tokens":10,"codedb":1,"insertions":3,"deletions":0}
{"session":"s1","cwd":"/a","rule":"on","out_tokens":300,"in_tokens":20,"codedb":4,"insertions":5,"deletions":1}
JSON
out="$(bash "$ROOT/bin/unc" stats | noansi)"
check "turns/sessions" "$(grep -c '2 turns across 1 sessions' <<<"$out")" "1"
# deduped: out=max(100,300)=300, ins=max=5, del=max=1 -> net 4 (NOT summed 400/10/5)
check "net loc"       "$(grep -oE 'net LOC +[0-9]+' <<<"$out" | grep -oE '[0-9]+' | head -1)" "4"
check "dedup tokens"  "$(grep -oE 'output tokens   [0-9]+' <<<"$out" | grep -oE '[0-9]+')" "300"
check "codedb max"    "$(grep -oE 'codedb queries  [0-9]+' <<<"$out" | grep -oE '[0-9]+')" "4"
# seed: out_on 300 * .65/.35 = 557 ; lines 5 * .54/.46 = 5
check "seed mode"       "$(grep -c 'trust me bro' <<<"$out")" "1"
check "seed tokens"     "$(grep -oE 'reckons ~[0-9]+ output tokens' <<<"$out" | grep -oE '[0-9]+')" "557"
check "seed loc est"    "$(grep -oE 'lines saved     ~[0-9]+' <<<"$out" | grep -oE '[0-9]+')" "5"

# --- measured mode: per-SESSION words/line rate, on vs off, median ---
# 2 on sessions rate 50/10=5, 3 off sessions rate 100/10=10. med off 10 - on 5 = 5.
# on lines shipped = 20. tok = 5*20 = 100. lines est 20*.54/.46 = 23.
cat > "$HOME/.unc/sessions.ndjson" <<'JSON'
{"session":"on1","rule":"on","out_tokens":50,"in_tokens":0,"insertions":10,"deletions":0}
{"session":"on2","rule":"on","out_tokens":50,"in_tokens":0,"insertions":10,"deletions":0}
{"session":"off1","rule":"off","out_tokens":100,"in_tokens":0,"insertions":10,"deletions":0}
{"session":"off2","rule":"off","out_tokens":100,"in_tokens":0,"insertions":10,"deletions":0}
{"session":"off3","rule":"off","out_tokens":100,"in_tokens":0,"insertions":10,"deletions":0}
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
check "share loc est"  "$(grep -c 'ponytail' <<<"$sc")" "1"

# --- --how prints methodology, no crash on empty-ish ---
check "how link" "$(bash "$ROOT/bin/unc" stats --how | grep -c 'METHODOLOGY.md')" "1"

# --- on/off toggle ---
bash "$ROOT/bin/unc" off >/dev/null; check "off writes flag" "$([ -f "$HOME/.unc/off" ] && echo y)" "y"
bash "$ROOT/bin/unc" on  >/dev/null; check "on clears flag"  "$([ -f "$HOME/.unc/off" ] || echo n)" "n"

echo "ok — $pass checks passed"