#!/bin/bash

POPUP_CLICK_SCRIPT="sketchybar --set \$NAME popup.drawing=toggle"

claude_main=(
  padding_right=6
  update_freq=120
  icon=$CLAUDE
  icon.font="$FONT:Bold:15.0"
  icon.color=$MAGENTA
  label=$LOADING
  label.color=$MAGENTA
  label.highlight_color=$MAGENTA
  popup.align=right
  script="$PLUGIN_DIR/claude.sh"
  click_script="$POPUP_CLICK_SCRIPT"
)

# Each popup row: an icon on the left, value as the label.
popup_row=(
  background.corner_radius=12
  padding_left=8
  padding_right=8
  icon.font="$FONT:Semibold:13.0"
  icon.padding_right=8
  label.font="$FONT:Semibold:13.0"
)

sketchybar --add event claude.update                          \
                                                              \
           --add item claude.main right                       \
           --set claude.main "${claude_main[@]}"              \
           --subscribe claude.main mouse.entered              \
                                   mouse.exited               \
                                   mouse.exited.global        \
                                   mouse.clicked              \
                                   system_woke                \
                                   claude.update              \
                                                              \
           --add item claude.tokens popup.claude.main         \
           --set claude.tokens "${popup_row[@]}"              \
                 icon="$CLAUDE_TOKENS" icon.color=$BLUE       \
                                                              \
           --add item claude.cost popup.claude.main           \
           --set claude.cost "${popup_row[@]}"                \
                 icon="$CLAUDE_COST" icon.color=$GREEN        \
                                                              \
           --add item claude.burn popup.claude.main           \
           --set claude.burn "${popup_row[@]}"                \
                 icon="$CLAUDE_BURN" icon.color=$ORANGE       \
                                                              \
           --add item claude.reset popup.claude.main          \
           --set claude.reset "${popup_row[@]}"               \
                 icon="$CLAUDE_RESET" icon.color=$YELLOW      \
                                                              \
           --add item claude.models popup.claude.main         \
           --set claude.models "${popup_row[@]}"              \
                 icon="$CLAUDE_MODELS" icon.color=$GREY
