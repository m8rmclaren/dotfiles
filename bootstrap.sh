curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux64.tar.gz

git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 ~/.local/share/nvim/site/pack/packer/start/packer.nvim

sudo apt install build-essential -y

mkdir -p ~/.local/bin
ln -s $HOME/.config/scripts/sessionizer ~/.local/bin

# Install tmux plugin manager
git clone https://github.com/tmux-plugins/tpm $HOME/.config/tmux/plugins/tpm

# Oh my zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Add to .zshrc
plugins=(
    git
    zsh-syntax-highlighting
    zsh-autosuggestions
)

# Install zsh-syntax-highlighting
sudo apt install zsh-syntax-highlighting
echo "source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ${ZDOTDIR:-$HOME}/.zshrc

# Put in .bashrc or .zshrc
source $HOME/.config/zsh/aliases.sh
export PATH="$PATH:/opt/nvim-linux64/bin"
export PATH="$HOME/.local/bin:$PATH"

# p10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k

sudo apt install fontconfig -y
sudo curl https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf -o /usr/local/share/fonts/MesloLGS\ NF\ Regular.ttf
sudo curl https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf -o /usr/local/share/fonts/MesloLGS\ NF\ Bold.ttf
sudo curl https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf -o /usr/local/share/fonts/MesloLGS\ NF\ Italic.ttf
sudo curl https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf -o /usr/local/share/fonts/MesloLGS\ NF\ Bold\ Italic.ttf
sudo fc-cache -fv

echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc

# Microk8s
sudo usermod -a -G microk8s $USER
newgrp microk8s
