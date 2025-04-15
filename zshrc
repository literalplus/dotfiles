#!/usr/bin/env zsh
# shellcheck disable=SC2034 shell=bash
# SC2034 wants us to export all variables but that's not how it works here

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$HOME/.local/bin:$PATH

if which go >/dev/null 2>&1; then
  MY_OWN_GOPATH="$(go env GOPATH)"
  export PATH=$PATH:$MY_OWN_GOPATH/bin
fi

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
HIST_STAMPS="yyyy-mm-dd"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git fzf z)

# SC1091 Don't follow link
# shellcheck disable=SC1091
source "$ZSH/oh-my-zsh.sh"

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

alias ssc='sudo systemctl'
alias grep='grep -i --color'
alias pacaur='echo please stop'
alias f='nautilus . &'

function choosecont() {
  if LINE=$(docker ps | fzf --header-lines=1); then
    echo "$LINE" | xargs | cut -d" " -f1
  fi
}

function rmcont() {
  if CID=$(choosecont); then
    echo "No container chosen."
  else
    docker rm -f "$CID"
  fi
}

function lgcont() {
  if CID=$(choosecont); then
    echo "No container chosen."
  else
    docker logs --since=15m -f "$CID"
  fi
}

function shcont() {
  CID=$(choosecont)
  if [[ -z "$CID" ]]; then
    echo "No container chosen."
  else
    docker exec -it "$CID" /bin/sh -c "/bin/bash || /bin/sh || /bin/sh"
  fi
}

function mkcd {
  if [ "$#" -ne 1 ]; then
    echo "mkcd needs exactly one argument!"
    exit 1
  fi
  mkdir "$1" || return 2
  cd "$1" || return 3
  echo "HENLO $1"
}

function hilite {
  grep --color -E "^|$1"
}

function sparkle {
  printf '\xE2\x9c\xA8'
}

function prepend-sudo {
  if [[ $BUFFER != "sudo "* ]]; then
    BUFFER="sudo $BUFFER"; CURSOR+=5
  fi
}
zle -N prepend-sudo

bindkey "^S" prepend-sudo

function cargo-pager {
  cargo build 2>&1 --color=always | less
}

function kubeseal-it {
  kubeseal -f $1 -o yaml -w $1
}

function browse-pacman {
  # from Arch Wiki: https://wiki.archlinux.org/title/pacman/Tips_and_tricks#Browsing_packages
  pacman -Qq | fzf --preview 'pacman -Qil {}' --layout=reverse --bind 'enter:execute(pacman -Qil {} | less)'
}

decode_k8s_secrets() {
  if [ -z "$1" ]; then
    echo "Usage: decode_k8s_secrets SEARCH_STRING"
    return 1
  fi

  SEARCH_STRING=$1
  echo "Searching for Kubernetes Secrets matching: $SEARCH_STRING"

  # Get all secrets matching the search string
  SECRETS=$(kubectl get secret | grep "$SEARCH_STRING" | awk '{print $1}')

  if [ -z "$SECRETS" ]; then
    echo "No Kubernetes Secrets found matching: $SEARCH_STRING"
    return 1
  fi

  # Use fzf to select a secret interactively
  SELECTED_SECRET=$(echo "$SECRETS" | fzf --prompt="Select a secret to decode: ")

  if [ -z "$SELECTED_SECRET" ]; then
    echo "No secret selected. Exiting."
    return 1
  fi

  echo "Decoding data from secret: $SELECTED_SECRET"
  kubectl get secret "$SELECTED_SECRET" -o yaml | yq '.data |= with_entries(.value |= @base64d)'
}


# Automatic appends below this line

# SC1091 Don't follow link
# shellcheck disable=SC1091
if [[ -f /usr/share/nvm/init-nvm.sh ]]; then
  source /usr/share/nvm/init-nvm.sh
fi
export JAVA_HOME=/usr/lib/jvm/default
