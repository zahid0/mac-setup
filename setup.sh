#!/bin/zsh

set -x

command -v brew >/dev/null || {
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && eval "$(/opt/homebrew/bin/brew shellenv)"
}

brew update
brew cleanup

# CLI tools
# ripgrep replaces the_silver_searcher (ag is unmaintained: last release 2.2.0 in 2018)
brew install \
  tmux \
  nvim \
  ripgrep \
  jq \
  fd \
  git \
  git-gui \
  universal-ctags \
  gh \
  python \
  node \
  tor \
  ffmpeg

# GUI apps (casks must be installed explicitly with --cask)
# - ungoogled-chromium: former "eloston-chromium" token (plain "chromium" cask is
#   disabled — it fails the macOS Gatekeeper check)
# - orbstack: lightweight Docker Desktop replacement (daemon + CLI, macOS-native VM)
brew install --cask \
  mullvad-browser \
  ungoogled-chromium \
  vlc \
  orbstack

# Symlink configs, backing up anything that's already there (idempotent on re-run)
link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "$dst.bak.$(date +%Y%m%d%H%M%S)"
  fi
  ln -sfn "$src" "$dst"
}

link "$(pwd)/configs/zshrc"              "$HOME/.zshrc"
link "$(pwd)/configs/tmux.conf"          "$HOME/.tmux.conf"
link "$(pwd)/configs/gitconfig"          "$HOME/.gitconfig"
link "$(pwd)/configs/vimrc"              "$HOME/.vimrc"
link "$(pwd)/configs/nvim/init.lua"      "$HOME/.config/nvim/init.lua"
# ~/.local/bin is already on PATH via zshrc; avoids needing sudo for /usr/local/bin
link "$(pwd)/scripts/pyformat.sh"        "$HOME/.local/bin/pyformat"

curl -fsSL https://raw.githubusercontent.com/mullvad/encrypted-dns-profiles/refs/heads/main/family/mullvad-encrypted-dns-https-family.mobileconfig -O
open mullvad-encrypted-dns-https-family.mobileconfig
open "x-apple.systempreferences:com.apple.preference.security?Privacy.profiles"

# macOS UI defaults (Dock, Finder, Terminal profile with auto-tmux)
./dock-settings.sh
./finder-settings.sh
./terminal-settings.sh
