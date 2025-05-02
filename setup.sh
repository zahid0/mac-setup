#/bin/zsh

set -x

which brew || ( /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && eval "$(/opt/homebrew/bin/brew shellenv)" )

brew cleanup

brew install \
  tmux \
  nvim \
  the_silver_searcher \
  jq \
  git \
  git-gui \
  universal-ctags \
  gh

mkdir -p ~/.config/nvim

ln -s $(pwd)/configs/zshrc ~/.zshrc
ln -s $(pwd)/configs/tmux.conf ~/.tmux.conf
ln -s $(pwd)/configs/gitconfig ~/.gitconfig
ln -s $(pwd)/configs/vimrc ~/.vimrc
ln -s $(pwd)/configs/nvim/init.lua ~/.config/nvim/init.lua
ln -s $(pwd)/scripts/pyformat.sh /usr/local/bin/pyformat

# defaults import com.apple.terminal configs/terminal-settings.plist
