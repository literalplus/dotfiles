#!/usr/bin/env bash

function psuc () {
  echo -e "\e[1;32m ++ \e[1;97m""$*""\e[0m"
}

function pok () {
  echo -e "\e[1;32m ok \e[1;97m""$*""\e[0m"
}

function pweaksuc () {
  echo -e "\e[32m ++ \e[2m""$*""\e[0m"
}

function pwrn () {
  echo -e "\e[1;33m !! \e[1;97m""$*""\e[0m"
}

function perr () {
  echo -e "\e[1;31m ** \e[1;97m""$*""\e[0m"
}

function psec () {
  echo -e "\e[1;34m :: \e[1;97m""$*""\e[0m"
}

function pask() {
  echo -e "\e[1;35m ?? \e[1;97m""$*""\e[0m"
}

function pnot () {
  echo -e "    \e[2m""$*""\e[0m"
}

function dim () {
  echo -e -n "\e[2m"
}

function undim () {
  echo -e -n "\e[22m"
}

function movelineup () {
  echo -e -n "\033[1A\r"
}

function exitifnok () {
  read -r choice
  movelineup
  movelineup
  if [ "$choice" = "y" ]; then
    psuc ""
  else
    perr ""
    exit 1
  fi
}

function applyln () {
  TEMPLATE="$(realpath "$1")"
  TARGET="$(realpath "$2")"
  TARGET_RAW="$2"
  if [ "$TEMPLATE" = "$TARGET" ]; then
    pnot "$TARGET_RAW already set up"
  elif [ -d "$TARGET" ]; then
    perr "$TARGET_RAW is a directory"
  elif [ ! -f "$TARGET" ]; then
    ln -s "$TEMPLATE" "$TARGET"
    psuc "$TARGET_RAW created"
  elif [ -f "$TARGET" ]; then
    pwrn "$TARGET_RAW exists already. Overwrite? (y/N)"
    read -r choice
    movelineup
    if [ "$choice" = "y" ]; then
      ln -sf "$TEMPLATE" "$TARGET"
      pnot "Local changes overwritten."
    else
      pnot "File left unchanged."
    fi
  else
    perr "$TARGET_RAW do be something else tho"
  fi
}

function applycp () {
  TEMPLATE="$(realpath "$1")"
  TARGET="$(realpath "$2")"
  TARGET_RAW="$2"
  OVERWRITE="$3"
  if [ "$TEMPLATE" = "$TARGET" ]; then
    pnot "$TARGET_RAW points to the template"
  elif [ -d "$TARGET" ]; then
    perr "$TARGET_RAW is a directory"
  elif [ ! -f "$TARGET" ]; then
    cp "$TEMPLATE" "$TARGET"
    psuc "$TARGET_RAW created"
  elif [ -f "$TARGET" ]; then
    if [ "$OVERWRITE" = "overwrite" ]; then
      # sha256sum outputs the filename, which we cut out obviously
      SHA_TEMPLATE=$(sha256sum "$TEMPLATE" | cut -d " " -f 1)
      SHA_TARGET=$(sha256sum "$TARGET" | cut -d " " -f 1)
      if [ "$SHA_TEMPLATE" != "$SHA_TARGET" ]; then
        psuc "$TARGET_RAW changed, overwriting."
        cp "$TEMPLATE" "$TARGET"
      else
        pweaksuc "$TARGET_RAW unchanged, leaving it alone."
      fi
    else
      pnot "$TARGET_RAW exists already"
    fi
  else
    perr "$TARGET_RAW do be something else tho"
  fi
}

function confirmbefore () {
  pask "Please confirm: $* (yes/EXIT/skip)"
  read -r choice
  movelineup
  movelineup
  if [ "$choice" = "yes" ] || [ "$choice" = "y" ]; then
    psuc ""
    if _exec_or_eval "$@"; then
      pok ""
    else
      perr "Command failed with status code $?"
      exit 1
    fi
  elif [ "$choice" = "skip" ]; then
    pwrn "Skipping:      "
  else
    perr ""
    exit 1
  fi
}

function _exec_or_eval() {
  # https://github.com/koalaman/shellcheck/issues/1141
  # shellcheck disable=SC2124
  lastarg="${@: -1}"
  use_eval="no"
  if [ "$lastarg" = "USING_UNSAFE_EVAL" ]; then
    unset 'argv[-1]'
    use_eval="yes"
    pok "evaling $*"
  fi
  if [ -n "$DRY_RUN" ]; then
    pnot "Dry-run, not executing."
  elif [ "$use_eval" = "yes" ]; then
    if eval "$*"; then
      pok ""
    else
      perr "Command failed with status code $?"
      exit 1
    fi
  else
    if "$@"; then
      pok ""
    else
      perr "Command failed with status code $?"
      exit 1
    fi
  fi
}

function destcmd () {
  pnot "$@"
  _exec_or_eval "$@"
}

[ -f "$HOME/dotfiles/is-personal" ]
export PERSONAL=$?
