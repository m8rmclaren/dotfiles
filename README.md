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
