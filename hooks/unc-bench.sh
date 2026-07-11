#!/usr/bin/env bash
# runs on Stop. logs one json line per turn: tokens (from the transcript) +
# code churn (git diff). must never break a turn, so always exit 0.
# ponytail: churn is `git diff --shortstat HEAD`, resets if you commit
# mid-session. fine for a personal trend; snapshot on SessionStart if you ever
# need it exact.

set -euo pipefail
command -v jq >/dev/null 2>&1 || exit 0   # no jq, no numbers — bail quietly

log_dir="$HOME/.unc"
mkdir -p "$log_dir"
log="$log_dir/sessions.ndjson"

payload="$(cat)"
transcript="$(printf '%s' "$payload" | jq -r '.transcript_path // empty')"
cwd="$(printf '%s' "$payload" | jq -r '.cwd // empty')"
[ -z "$cwd" ] && cwd="$PWD"

out=0; in=0
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  out="$(jq -r 'select(.message.usage.output_tokens) | .message.usage.output_tokens' "$transcript" 2>/dev/null | awk '{s+=$1} END{print s+0}')"
  # input is split into input_tokens + cache reads; the big context is cached, so sum both
  in="$(jq -r 'select(.message.usage) | .message.usage | (.input_tokens // 0) + (.cache_read_input_tokens // 0) + (.cache_creation_input_tokens // 0)' "$transcript" 2>/dev/null | awk '{s+=$1} END{print s+0}')"
fi

files=0; ins=0; del=0
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  # " 3 files changed, 40 insertions(+), 8 deletions(-)" -> 3 40 8
  read -r files ins del < <(git -C "$cwd" diff --shortstat HEAD 2>/dev/null | awk '
    { f=0;i=0;d=0;
      for(x=1;x<=NF;x++){
        if($x ~ /^[0-9]+$/){ n=$x;
          if($(x+1) ~ /file/)       f=n;
          else if($(x+1) ~ /insert/) i=n;
          else if($(x+1) ~ /delet/)  d=n; } }
      print f, i, d } END { if(NR==0) print 0,0,0 }')
fi
files=${files:-0}; ins=${ins:-0}; del=${del:-0}

# tag the row with whether the rule was on — this is what makes the A/B real
rule="on"; [ -f "$HOME/.unc/off" ] && rule="off"

ts="$(date -u +%FT%TZ)"
printf '{"ts":"%s","cwd":"%s","rule":"%s","out_tokens":%s,"in_tokens":%s,"files":%s,"insertions":%s,"deletions":%s}\n' \
  "$ts" "$cwd" "$rule" "${out:-0}" "${in:-0}" "$files" "$ins" "$del" >> "$log"

exit 0