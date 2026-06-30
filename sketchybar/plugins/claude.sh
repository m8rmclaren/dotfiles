#!/bin/bash

# Claude Code usage widget.
#
# Data source: `ccusage`, which estimates token usage / cost for the *current*
# 5-hour billing window by parsing the local session logs in
# ~/.claude/projects/*.jsonl. No network and no auth — these are estimates from
# your own logs, not Anthropic's authoritative plan limits (there is no public
# API for Pro/Max subscription limits; `/usage` in the CLI is the only official
# view). The 5h window is rolling and time-based, so "resets in" is real, while
# token/cost figures are best-effort estimates.

# sketchybar launches plugins with a minimal PATH, so locate a node bin dir
# (nvm-managed installs are versioned) and the usual Homebrew locations.
NODE_BIN=$(ls -d "$HOME"/.nvm/versions/node/*/bin 2>/dev/null | sort -V | tail -n1)
export PATH="$NODE_BIN:/opt/homebrew/bin:/usr/local/bin:$PATH"

if command -v ccusage >/dev/null 2>&1; then
  RUN=(ccusage)
else
  RUN=(npx -y ccusage)   # first run installs into the npx cache, then reuses it
fi

humanize() { # tokens -> 1.2K / 3.4M / 5.6B
  awk -v n="$1" 'BEGIN{
    if (n>=1e9)      printf "%.1fB", n/1e9;
    else if (n>=1e6) printf "%.1fM", n/1e6;
    else if (n>=1e3) printf "%.1fK", n/1e3;
    else             printf "%d",    n;
  }'
}

update() {
  source "$CONFIG_DIR/colors.sh"
  source "$CONFIG_DIR/icons.sh"

  JSON="$("${RUN[@]}" blocks --active --offline --json 2>/dev/null)"
  ACTIVE="$(echo "$JSON" | jq -r '.blocks | length' 2>/dev/null)"

  if [ -z "$ACTIVE" ] || [ "$ACTIVE" = "0" ] || [ "$ACTIVE" = "null" ]; then
    # No active 5h window -> idle.
    sketchybar --set claude.main icon.color=$GREY label.color=$GREY label="idle" \
               --set claude.tokens label="No active 5h window"                   \
               --set claude.cost   drawing=off                                   \
               --set claude.burn   drawing=off                                   \
               --set claude.reset  drawing=off                                   \
               --set claude.models drawing=off
    return
  fi

  read -r TOKENS COST IND REM MODELS <<<"$(echo "$JSON" | jq -r '
    .blocks[0] |
    [ .totalTokens,
      .costUSD,
      (.burnRate.tokensPerMinuteForIndicator // 0),
      (.projection.remainingMinutes // 0),
      ( .models | map(sub("claude-";"") | sub("-[0-9]+$";"")) | join(", ") )
    ] | @tsv' 2>/dev/null)"

  # Color cue from burn rate (ccusage's own indicator metric, cache-excluded).
  COLOR=$GREEN
  awk -v i="$IND" 'BEGIN{exit !(i>=4000)}' && COLOR=$RED
  [ "$COLOR" = "$GREEN" ] && { awk -v i="$IND" 'BEGIN{exit !(i>=1000)}' && COLOR=$YELLOW; }

  H_TOKENS="$(humanize "$TOKENS")"
  H_BURN="$(humanize "$IND")"
  RESET="$(printf '%dh %02dm' $((REM/60)) $((REM%60)))"

  # Main label: humanized tokens + whole-dollar cost.
  sketchybar --set claude.main icon.color=$COLOR label.color=$COLOR \
                   label="$(printf '%s · $%.0f' "$H_TOKENS" "$COST")" \
             --set claude.tokens drawing=on label="$(printf '%s tokens' "$H_TOKENS")" \
             --set claude.cost   drawing=on label="$(printf '$%.2f this window' "$COST")" \
             --set claude.burn   drawing=on label="$(printf '%s tok/min' "$H_BURN")" \
             --set claude.reset  drawing=on label="resets in $RESET" \
             --set claude.models drawing=on label="$MODELS"
}

popup() { sketchybar --set claude.main popup.drawing=$1; }

case "$SENDER" in
  "routine"|"forced"|"claude.update") update ;;
  "system_woke") update ;;
  "mouse.entered") popup on ;;
  "mouse.exited"|"mouse.exited.global") popup off ;;
  "mouse.clicked") popup toggle ;;
esac
