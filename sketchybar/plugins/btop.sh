#!/bin/bash
# Toggle a "btop" tmux window in the active session.
#   - on btop already  -> jump back to previous window
#   - btop exists       -> focus it
#   - btop missing      -> create it
#   - no tmux server    -> start one (attached in a new iTerm window)

WINDOW_NAME="btop"

# Session the attached iTerm client is viewing; fall back to most-recent session.
session="$(tmux list-clients -F '#{session_name}' 2>/dev/null | head -n1)"
[ -z "$session" ] && session="$(tmux list-sessions -F '#{session_name}' 2>/dev/null | head -n1)"

# No server/session at all -> bootstrap detached, then attach in a fresh iTerm window.
if [ -z "$session" ]; then
  tmux new-session -d -s main -n "$WINDOW_NAME" btop
  osascript -e 'tell application "iTerm" to create window with default profile command "tmux attach -t main"'
  exit 0
fi

# Name of the window currently active in that session.
current="$(tmux display-message -p -t "$session" '#{window_name}' 2>/dev/null)"

if [ "$current" = "$WINDOW_NAME" ]; then
  tmux last-window -t "$session"                        # toggle away
elif tmux list-windows -t "$session" -F '#{window_name}' 2>/dev/null | grep -qx "$WINDOW_NAME"; then
  tmux select-window -t "${session}:${WINDOW_NAME}"     # focus existing
else
  tmux new-window -t "$session" -n "$WINDOW_NAME" btop  # create
fi

open -a iTerm
