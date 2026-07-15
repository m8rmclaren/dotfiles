#!/bin/bash

# Trigger the brew_udpate event when brew update or upgrade is run from cmdline
# e.g. via function in .zshrc

POPUP_CLICK_SCRIPT="sketchybar --set \$NAME popup.drawing=toggle"

# Max package rows shown in the popup. SketchyBar popups can't scroll (they're a
# plain vertical stack), so we cap the list to stay compact and surface the
# remainder via the "+N more" footer. Keep in sync with MAX_ROWS in plugins/brew.sh.
BREW_MAX_ROWS=15

brew=(
  icon=􀐛
  label=?
  padding_right=10
  update_freq=3600
  popup.align=right
  script="$PLUGIN_DIR/brew.sh"
  click_script="$POPUP_CLICK_SCRIPT"
)

# Popup row styling. A compact monospace label keeps the "cur → latest" columns
# aligned (SF Pro is proportional, so it wouldn't line up).
pkg_row=(
  background.corner_radius=12
  padding_left=8
  padding_right=8
  icon.font="$HIST_FONT:Regular:11.0"
  icon.color=$GREY
  icon.padding_right=8
  label.font="$HIST_FONT:Regular:11.0"
  label.color=$WHITE
)

sketchybar --add event brew_update       \
           --add item brew right         \
           --set brew "${brew[@]}"       \
           --subscribe brew brew_update  \
                            mouse.entered \
                            mouse.exited  \
                            mouse.exited.global \
                            mouse.clicked

# Header row: total outdated count.
sketchybar --add item brew.header popup.brew    \
           --set brew.header "${pkg_row[@]}"     \
                 icon=􀐛 icon.color=$ORANGE       \
                 label.color=$GREY

# Fixed pool of package rows, toggled on/off by the plugin.
for i in $(seq 1 "$BREW_MAX_ROWS"); do
  sketchybar --add item "brew.pkg.$i" popup.brew \
             --set "brew.pkg.$i" "${pkg_row[@]}" drawing=off
done

# Footer row: "+N more" when the list is truncated.
sketchybar --add item brew.more popup.brew \
           --set brew.more "${pkg_row[@]}"  \
                 icon=􀄼 icon.color=$YELLOW   \
                 label.color=$YELLOW drawing=off
