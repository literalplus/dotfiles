#!/usr/bin/env bash

function psuc () {
  echo -e "\e[1;32m ++ \e[1;97m""$@""\e[0m"
}

function pwrn () {
  echo -e "\e[1;33m !! \e[1;97m""$@""\e[0m"
}

function perr () {
  echo -e "\e[1;31m ** \e[1;97m""$@""\e[0m"
}

function psec () {
  echo -e "\e[1;34m :: \e[1;97m""$@""\e[0m"
}

function pask() {
  echo -e "\e[1;35m ?? \e[1;97m""$@""\e[0m"
}

function pnot () {
  echo -e "    \e[2m""$@""\e[0m"
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
  read choice
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
  TEMPLATE="$(realpath $1)"
  TARGET="$(realpath $2)"
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
    read choice
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
  TEMPLATE="$(realpath $1)"
  TARGET="$(realpath $2)"
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
      psuc "$TARGET_RAW overwritten"
    else
      pnot "$TARGET_RAW exists already"
    fi
  else
    perr "$TARGET_RAW do be something else tho"
  fi
}

function confirmbefore () {
  $COMMAND=$@
  pask "Please confirm: $@ (yes/EXIT/skip)"
  read choice
  movelineup
  movelineup
  if [ "$choice" = "yes" ]; then
    psuc ""
    if [ -z "$DRY_RUN" ]; then
      "$@"
      if [ "$?" -ne 0 ]; then
        perr "Command failed with status code $?"
        exit 1
      fi
    fi
  elif [ "$choice" = "skip" ]; then
    pwrn "Skipping:      "
  else
    perr ""
    exit 1
  fi
}

function destcmd () {
  pnot "$@"
  if [ -z "$DRY_RUN" ]; then
    "$@"
    RET=$?
    if [ "$RET" -ne 0 ]; then
      perr "Process exited with code $RET"
      exit 1
    else
      return $RET
    fi
  else
    movelineup
    echo "dry "
  fi
}

[ -f "$HOME/dotfiles/is-personal" ]
PERSONAL=$?
