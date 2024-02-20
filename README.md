# ~/.config

> Setup
> ```shell
> [[ ! -f ~/.config ]] && mkdir .config
> cd .config
> git remote add origin git@github.com:m8rmclaren/dotfiles.git
> git fetch
> git checkout origin/main -ft
> ```

Software
```shell
# Homebrew
## Install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

## Formulae

### Essentials
brew install wget
brew install jq
brew install ripgrep
brew install skhd
brew install sketchybar

### Terminal
brew install tmux
brew install neovim
brew install zsh-autosuggestions
brew install zsh-syntax-highlighting
echo "source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ${ZDOTDIR:-$HOME}/.zshrc

## Casks

### Fonts
brew install --cask sf-symbols

## Taps
brew tap FelixKratz/formulae

## Essentials
brew install borders

# Icons
curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.4/sketchybar-app-font.ttf -o $HOME/Library/Fonts/sketchybar-app-font.ttf
```

Spicetify
```shell
curl -fsSL https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.sh -O
chmod +x install.sh
./install.sh
spicetify backup apply
rm install.sh

spicetify config inject_css 1
spicetify config replace_colors 1
spicetify config current_theme marketplace
spicetify config custom_apps marketplace
spicetify apply
```
