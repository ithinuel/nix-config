# configure zsh
ln -s $(dirname $0)/.zshrc $HOME/.zshrc

# configure i3
mkdir -p .config/i3
ln -s $(dirname $0)/.config/i3/* $HOME/.config/i3/

# configure nvim
mkdir -p .config/nvim
ln -s $(dirname $0)/.config/nvim/* $HOME/.config/nvim/

# Configure gdb
cat > $HOME/.gdbinit <<EOF
set print pretty on

python

import os

gdb.execute('source' + os.environ['HOME'] + '/Document/dotfiles/gdb-dashboard/.gdbinit')
gdb.execute('source' + os.environ['HOME'] + '/Document/dotfiles/openocd.gdb')

end
EOF

# install vim plug
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
