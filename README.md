# ~/.config

> Setup
> ```shell
> [[ ! -f ~/.config ]] && mkdir .config
> cd .config
> git init .
> git remote add origin git@github.com:m8rmclaren/dotfiles.git
> git fetch
> git checkout origin/main -ft
> ```

Software
```shell
# Homebrew
## Install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

## Yabai
brew install koekeishiya/formulae/yabai
yabai --start-service

## SKHD
brew install koekeishiya/formulae/skhd
skhd --start-service

## FelixKratz
brew tap FelixKratz/formulae
brew install borders
brew install sketchybar
brew install --cask font-sketchybar-app-font

brew services start borders
brew services start sketchybar

## tmux
brew install tmux
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

## Terminal
brew install neovim
brew install fzf

### OMZ
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

## Other software
brew install wget jq ripgrep awscli coreutils
brew install --cask spotify
brew install --cask obsidian

brew tap hashicorp/tap
brew install hashicorp/tap/terraform

## Programming languages
brew install go pyenv cmake
brew install nvm

### https://github.com/pyenv/pyenv?tab=readme-ov-file#zsh
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(pyenv init - zsh)"' >> ~/.zshrc

### nvm
echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
echo '[ -s "$(brew --prefix nvm)/nvm.sh" ] && \. "$(brew --prefix nvm)/nvm.sh"' >> ~/.zshrc
echo '[ -s "$(brew --prefix nvm)/etc/bash_completion.d/nvm" ] && \. "$(brew --prefix nvm)/etc/bash_completion.d/nvm"' >> ~/.zshrc

pyenv install 3.11.8
nvm install node

brew install --cask sf-symbols
brew install font-hack-nerd-font
```

```shell
❯ brew list
==> Formulae
autoconf                cmctl                   gnupg                   libffi                  libvterm                ncurses                 pycparser               tmux
automake                coreutils               gnutls                  libgcrypt               libx11                  neofetch                pyenv                   tree
awscli                  cosign                  go                      libgit2                 libxau                  neovim                  python@3.10             tree-sitter
azure-cli               cryptography            golangci-lint           libgpg-error            libxcb                  nettle                  python@3.11             unbound
base64                  deno                    graphite2               libidn2                 libxdmcp                node                    python@3.12             unibilium
bat                     docker-compose          harfbuzz                libksba                 libxext                 npth                    python@3.13             utf8proc
bison                   dtc                     helm                    libnghttp2              libxrender              oniguruma               qemu                    vault
borders                 expat                   icu4c@77                libpng                  libyaml                 openjdk@11              readline                vde
brotli                  fontconfig              istioctl                libslirp                little-cms2             openssl@1.1             regclient               wget
c-ares                  freetype                jpeg-turbo              libsodium               lpeg                    openssl@3               ripgrep                 xorgproto
ca-certificates         fzf                     jq                      libssh                  luajit                  p11-kit                 ruby-install            xz
cairo                   gdbm                    k9s                     libssh2                 luv                     pcre2                   screenresolution        yabai
capstone                gettext                 kind                    libtasn1                lz4                     pinentry                sketchybar              yq
cffi                    gh                      kubebuilder             libtiff                 lzo                     pixman                  skhd                    zsh-autosuggestions
chart-releaser          giflib                  kubelogin               libunistring            m4                      pkgconf                 snappy                  zsh-syntax-highlighting
chruby                  glib                    libassuan               libusb                  mpdecimal               pnpm                    sqlite                  zstd
cmake                   gmp                     libevent                libuv                   msgpack                 pulumi                  terraform

==> Casks
font-hack-nerd-font     google-cloud-sdk        iterm2                  kitty                   powershell              qmk-toolbox             sf-symbols
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
