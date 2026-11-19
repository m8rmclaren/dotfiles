export PATH="$HOME/.local/bin/:$PATH"
# compinit is run by oh-my-zsh; source this file after oh-my-zsh.sh

if command -v kubectl >/dev/null 2>&1; then
  source <(kubectl completion zsh)
fi

# pbcopy is macOS-only; map it to the X11 clipboard elsewhere
if ! command -v pbcopy >/dev/null 2>&1 && command -v xclip >/dev/null 2>&1; then
  pbcopy() { xclip -selection clipboard "$@"; }
fi

alias projectizer='source $HOME/.config/scripts/projectizer'
alias cdd='source $HOME/.config/scripts/cdd'
alias aliaser='source $HOME/.config/scripts/aliaser'
alias gotest='source $HOME/.config/scripts/go/gotest.sh'
alias edit='nvim .'
alias oo='cd "$HOME/Documents/Obsidian Vault/"'
alias pubip='curl -s https://ifconfig.me | tee >(pbcopy); echo; echo "ip copied to clipboard"'
alias leetcode='source $HOME/.config/scripts/leetcode'
alias checkout='source $HOME/.config/scripts/checkout'
alias claude-pane='$HOME/.config/scripts/claude-pane'

sessionizer() {
  $HOME/.config/scripts/sessionizer "$@"
}


# hdev is vendored per-repo (see hermes/scripts/hdev). Resolve via the git COMMON
# dir, not the toplevel, so every worktree runs the primary checkout's copy — a
# half-finished edit on a wip/ branch must not break another session's stack.
hdev() {
  local repo
  repo="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" \
    && repo="$(dirname "$repo")"
  if [ -n "$repo" ] && [ -x "$repo/scripts/hdev" ]; then
    "$repo/scripts/hdev" "$@"
  else
    echo "hdev: no scripts/hdev in this repo" >&2; return 1
  fi
}
