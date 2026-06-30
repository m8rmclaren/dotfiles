export PATH="$HOME/.local/bin/:$PATH"

if command -v kubectl >/dev/null 2>&1; then
  source <(kubectl completion zsh)
fi

alias projectizer='source $HOME/.config/scripts/projectizer'
alias cdd='source $HOME/.config/scripts/cdd'
alias aliaser='source $HOME/.config/scripts/aliaser'
alias gotest='source $HOME/.config/scripts/go/gotest.sh'
alias edit='nvim .'
alias oo='cd "$HOME/Documents/Obsidian Vault/"'
alias pubip='curl -s https://ifconfig.me | tee >(pbcopy); echo; echo "ip copied to clipboard"'
alias leetcode='source $HOME/.config/scripts/leetcode'

export AWS_PROFILE=cypress-prod
sessionizer() {
  $HOME/.config/scripts/sessionizer "$@"
}

# Auto-load .env when entering a directory
function chpwd() {
  if [[ -f .env ]]; then
    echo -n "Load .env? [y/N] "
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      set -o allexport
      source .env
      set +o allexport
      echo "✓ Loaded .env"
    else
      echo "– Skipped .env"
    fi
  fi
}
