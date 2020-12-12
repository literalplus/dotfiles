#!/usr/bin/env bash
# For $HOME/.gitconfig: (Credit mschreiber)
#[alias]
#    cleanup = "!git branch --merged | grep -v '^  master$' | grep -v '^  development$' | grep -v '^* ' | xargs git branch -d"
#    force-cleanup = "!git branch | grep -v '^  master$' | grep -v '^  development$' | grep -v '^* ' | xargs git branch -D"

CLEANUP_OP="cleanup"

if [[ "$1" == "tomaster" ]]; then
  TOMASTER="yes"
fi

if [[ "$1" == "extremeyeetmode" ]]; then
  TOMASTER="yes"
  CLEANUP_OP="force-cleanup"
fi

function cleanrepo() {
  if [[ -d ".git" ]]; then
    BRANCH=$(git rev-parse --abbrev-ref HEAD | tr -d '\n')
    echo " ... Processing ${PWD##*/} at branch $BRANCH"
    if [[ "$TOMASTER" == "yes" ]]; then
      if git rev-parse --verify development >/dev/null 2>&1; then
        if [[ "$BRANCH" != "development" ]]; then
          echo " Checking out development"
          git checkout development
        fi
      elif [[ "$BRANCH" != "master" ]]; then
        echo " Checking out master"
        git checkout master
      fi
    fi
    if [[ "$CLEANUP_OP" == "force-cleanup" ]]; then
      git branch --merged | grep -v '^  master$' | grep -v '^  development$' | grep -v '^* ' | xargs git branch -d
    else
      git branch | grep -v '^  master$' | grep -v '^  development$' | grep -v '^* ' | xargs git branch -D
    fi
  else
    echo " --- Not a git repository: ${PWD##*/}"
  fi
}

for dirname in ./*/; do
  pushd "$dirname" >/dev/null || exit
  cleanrepo
  if [[ -x "cleanup.sh" ]]; then
    echo " Recursing into subdirectory $dirname..."
    ./cleanup.sh "$@"
  fi
  popd >/dev/null || exit
done

# Also try current directory
cleanrepo
