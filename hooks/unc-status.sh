#!/usr/bin/env bash
# optional statusline. shows tokens TRACKED, not "saved" — no baseline, no
# saved claim. wire it yourself (README); unc won't touch a statusline you have.

log="$HOME/.unc/sessions.ndjson"
mode="on"; [ -f "$HOME/.unc/off" ] && mode="off"

if command -v jq >/dev/null 2>&1 && [ -f "$log" ]; then
  # rows are cumulative per session -> de-dupe (max per session), never sum rows
  read -r n out < <(jq -s '[length, ([group_by(.session // .cwd)[] | (map(.out_tokens)|max // 0)] | add // 0)] | @tsv' -r "$log" 2>/dev/null)
  printf 'unc:%s · %s turns · %.1fk out-tok' "$mode" "${n:-0}" "$(awk "BEGIN{print ${out:-0}/1000}")"
else
  printf 'unc:%s' "$mode"
fi