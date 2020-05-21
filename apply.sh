#!/usr/bin/env bash
source lib.sh

if [ "$PWD" != "$HOME/dotfiles" ]; then
  perr "Please place this repository in your home directory."
  exit 1
fi

# Base
applyln "~~FINDER_README~~.txt" "$HOME/~~FINDER_README~~.txt"
applyln "base/tmux.conf" "$HOME/.tmux.conf"
applyln "base/vimrc" "$HOME/.vimrc"

# Coding tools
applycp "code/gitconfig-tpl" "$HOME/.gitconfig"

# Personal
if [ "$PERSONAL" -eq 0 ]; then
  pnot personal tbd
fi
