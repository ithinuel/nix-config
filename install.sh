BASE=$(realpath $(dirname $0))

# configure zsh
ln -s $BASE/.zshrc $HOME/.zshrc

# configure i3
mkdir -p $HOME/.config/i3
ln -s $BASE/.config/i3/* $HOME/.config/i3/
mkdir -p $HOME/.config/i3status
ln -s $BASE/.config/i3status/* $HOME/.config/i3status/

# configure nvim
mkdir -p $HOME/.config/nvim
ln -s $BASE/.config/nvim/* $HOME/.config/nvim/

# configure ssh-agent
mkdir -p $HOME/.config/systemd/user
ln -s $BASE/.config/systemd/user/* $HOME/.config/systemd/user/
systemctl --user enable ssh-agent.service


# Configure gdb
cat > $HOME/.gdbinit <<EOF
set print pretty on

python

import os

gdb.execute('source' + os.environ['HOME'] + '/Documents/dotfiles/gdb-dashboard/.gdbinit')
gdb.execute('source' + os.environ['HOME'] + '/Documents/dotfiles/openocd.gdb')

end
EOF

# install vim plug
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# sudo apt install zsh neovim curl build-essentials powerline nodejs yarnpkg libssl-dev gitk git-gui
# sudo apt install suckless-tools nitrogen i3-status udiskie
# chsh -s /bin/zsh

# install rust
# curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# cargo install bat cargo-update exa fd-find just navi ripgrep skim
