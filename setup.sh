#/bin/bash

set -x

# install brew
brew doctor || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew install \
  tmux \
  nvim \
  the_silver_searcher \
  jq \
  git \
  git-gui \
  universal-ctags \
  gh \
  python \
  node \
  tor \
  mullvad-browser \
  eloston-chromium \
  vmware-fusion

mkdir -p ~/.config/nvim

ln -s $(pwd)/configs/nvim/init.lua ~/.config/nvim/init.lua
ln -s $(pwd)/configs/tmux.conf ~/.tmux.conf
ln -s $(pwd)/configs/zshrc ~/.zshrc
ln -s $(pwd)/configs/gitconfig ~/.gitconfig
