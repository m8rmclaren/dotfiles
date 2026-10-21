#!/bin/bash

WIDTH=100

# Read a numeric field off an item, or echo a fallback. A query for an item that
# does not exist yet (plugins fire while the config is reloading) prints a
# non-JSON error, so guard both the query and the jq parse.
query_num() {
  local item="$1" field="$2" fallback="$3" out
  out="$(sketchybar --query "$item" 2>/dev/null | jq -r "$field" 2>/dev/null)"
  case "$out" in
    ''|null|*[!0-9]*) echo "$fallback" ;;
    *) echo "$out" ;;
  esac
}

volume_change() {
  source "$CONFIG_DIR/icons.sh"

  # A non-numeric INFO would break the comparison below.
  case "$INFO" in
    ''|*[!0-9]*) return ;;
  esac
  case $INFO in
    [6-9][0-9]|100) ICON=$VOLUME_100
    ;;
    [3-5][0-9]) ICON=$VOLUME_66
    ;;
    [1-2][0-9]) ICON=$VOLUME_33
    ;;
    [1-9]) ICON=$VOLUME_10
    ;;
    0) ICON=$VOLUME_0
    ;;
    *) ICON=$VOLUME_100
  esac

  sketchybar --set volume_icon label=$ICON \
             --set $NAME slider.percentage=$INFO

  INITIAL_WIDTH="$(query_num "$NAME" ".slider.width" 0)"
  if [ "$INITIAL_WIDTH" -eq 0 ]; then
    sketchybar --animate tanh 30 --set $NAME slider.width=$WIDTH 
  fi

  sleep 2

  # Check wether the volume was changed another time while sleeping
  # -1 never matches INFO, so a failed query leaves the slider open rather than
  # collapsing it out from under a volume change that is still in flight.
  FINAL_PERCENTAGE="$(query_num "$NAME" ".slider.percentage" -1)"
  if [ "$FINAL_PERCENTAGE" -eq "$INFO" ]; then
    sketchybar --animate tanh 30 --set $NAME slider.width=0
  fi
}

mouse_clicked() {
  osascript -e "set volume output volume $PERCENTAGE"
}

case "$SENDER" in
  "volume_change") volume_change
  ;;
  "mouse.clicked") mouse_clicked
  ;;
esac
