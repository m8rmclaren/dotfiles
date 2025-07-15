# source <(kubectl completion zsh)

alias projectizer='source $HOME/.config/scripts/projectizer'
alias cdd='source $HOME/.config/scripts/cdd'
alias aliaser='source $HOME/.config/scripts/aliaser'
alias gotest='source $HOME/.config/scripts/go/gotest.sh'
alias edit='nvim .'
alias oo='cd "$HOME/Documents/Obsidian Vault/"'
alias pubip='curl -s https://ifconfig.me | tee >(pbcopy); echo; echo "ip copied to clipboard"'

sessionizer() {
  $HOME/.config/scripts/sessionizer "$@"
}
