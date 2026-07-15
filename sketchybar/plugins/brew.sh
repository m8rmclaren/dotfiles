#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Max package rows rendered in the popup. Keep in sync with BREW_MAX_ROWS in
# items/brew.sh (the fixed pool of brew.pkg.N items we toggle on/off here).
MAX_ROWS=15

# SketchyBar spawns plugins with SIGCHLD set to SIG_IGN. That disposition is
# inherited across exec into brew (Ruby), which then can't reap its own child
# processes -- Hardware::CPU.cores crashes with "undefined method 'success?'
# for nil" and `brew outdated` exits non-zero with no output. bash can't reset
# a signal that was SIG_IGN at startup, so run brew through a perl wrapper that
# restores SIGCHLD to its default disposition first.
brew_outdated() {
  perl -e '$SIG{CHLD} = "DEFAULT"; exec @ARGV' brew outdated --verbose
}

# Fill the popup rows from `brew outdated --verbose`, whose lines look like:
#   name (installed[, installed...]) < latest
# We show the newest installed version -> latest, one package per row, capped at
# MAX_ROWS with a "+N more" footer for the rest.
populate_popup() {
  local outdated="$1" count="$2" row=0 line name rest installed latest cur short

  sketchybar --set brew.header label="$count package$([ "$count" = 1 ] || echo s) outdated"

  while IFS= read -r line; do
    [ -z "$line" ] && continue
    row=$((row + 1))
    [ "$row" -gt "$MAX_ROWS" ] && break

    name="${line%% (*}"        # everything before " ("
    rest="${line#* (}"         # "installed[, installed]) < latest"
    installed="${rest%%)*}"    # "installed[, installed]"
    latest="${line##*< }"      # after "< "
    cur="${installed##*, }"    # newest installed version
    short="${name##*/}"        # strip any tap prefix (foo/bar/pkg -> pkg)

    sketchybar --set "brew.pkg.$row" drawing=on icon=􀐗 \
               label="$(printf '%-16.16s %s → %s' "$short" "$cur" "$latest")"
  done <<<"$outdated"

  # Hide any leftover rows from a previous (longer) run.
  local i
  for ((i = row + 1; i <= MAX_ROWS; i++)); do
    sketchybar --set "brew.pkg.$i" drawing=off
  done

  if [ "$count" -gt "$MAX_ROWS" ]; then
    sketchybar --set brew.more drawing=on \
               label="+$((count - MAX_ROWS)) more · run brew upgrade"
  else
    sketchybar --set brew.more drawing=off
  fi
}

update() {
  # Capture output and exit status separately so a brew failure isn't silently
  # treated as "0 outdated" (which would masquerade as the all-clear checkmark).
  local OUTDATED STATUS COUNT COLOR
  OUTDATED="$(brew_outdated 2>/dev/null)"
  STATUS=$?

  if [ $STATUS -ne 0 ]; then
    # brew errored (crash, not on PATH, network) -- surface it, don't fake all-clear
    sketchybar --set "$NAME" label=􀇾 icon.color=$RED
    return
  fi

  if [ -z "$OUTDATED" ]; then
    COUNT=0
  else
    COUNT="$(echo "$OUTDATED" | wc -l | tr -d ' ')"
  fi

  COLOR=$RED
  case "$COUNT" in
    [3-5][0-9]|[6-9][0-9]|[1-9][0-9][0-9]) COLOR=$ORANGE ;;
    [1-2][0-9]) COLOR=$YELLOW ;;
    [1-9]) COLOR=$WHITE ;;
    0) COLOR=$GREEN ;;
  esac

  if [ "$COUNT" = 0 ]; then
    sketchybar --set "$NAME" label=􀆅 icon.color=$COLOR
  else
    sketchybar --set "$NAME" label="$COUNT" icon.color=$COLOR
    populate_popup "$OUTDATED" "$COUNT"
  fi
}

popup() { sketchybar --set brew popup.drawing="$1"; }

case "$SENDER" in
  "mouse.entered")                     popup on ;;
  "mouse.exited"|"mouse.exited.global") popup off ;;
  "mouse.clicked")                     popup toggle ;;
  *)                                    update ;;
esac
