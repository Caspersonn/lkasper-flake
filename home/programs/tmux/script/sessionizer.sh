#!/usr/bin/env bash

BASE_DIR="$HOME/git"   # change this

action="$1"
arg_name="$2"

# -----------------------------------------------------------
# Helper: list repos & show only last 2 path components
# -----------------------------------------------------------
list_repos() {
  find "$BASE_DIR" -type d -maxdepth 3 -name .git 2>/dev/null \
    | sed 's|/.git$||' \
    | awk -F/ '
      {
        if (NF >= 2) {
          print $(NF-1) "/" $NF
        } else {
          print $NF
        }
      }
    '
}

# Map displayed "parent/repo" back to full absolute path
resolve_path() {
  local display="$1"
  find "$BASE_DIR" -type d -maxdepth 3 -name .git 2>/dev/null \
    | sed 's|/.git$||' \
    | grep "$display"$ | head -n 1
}

# -----------------------------------------------------------
# OPTION 1 — OPEN SESSION
# -----------------------------------------------------------
if [ "$action" = "open" ]; then

  # Direct open: tmux-sessionizer open myrepo
  if [ -n "$arg_name" ]; then
    REPO="$(resolve_path "$arg_name")"
    if [ -z "$REPO" ]; then
      echo "No repo matches: $arg_name"
      exit 1
    fi

  else
    # fzf picker
    DISPLAY="$(list_repos | fzf-tmux -p 80%,60% --prompt='Repos > ')"
    [ -z "$DISPLAY" ] && exit 0
    REPO="$(resolve_path "$DISPLAY")"
  fi

  SESSION="$(basename "$REPO")"

  # Reattach if exists
  if tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux switch-client -t "$SESSION" 2>/dev/null || tmux attach -t "$SESSION"
    exit 0
  fi

  # Create session
  if [ -n "$TMUX" ]; then
    tmux new-session -ds "$SESSION" -c "$REPO"
    tmux switch-client -t "$SESSION"
  else
    tmux new-session -s "$SESSION" -c "$REPO"
  fi

  exit 0
fi

# -----------------------------------------------------------
# OPTION 2 — KILL SESSION
# -----------------------------------------------------------
if [ "$action" = "kill" ]; then

  # Direct kill by name: tmux-sessionizer kill myrepo
  if [ -n "$arg_name" ]; then
    if tmux has-session -t "$arg_name" 2>/dev/null; then
      tmux kill-session -t "$arg_name"
      exit 0
    else
      echo "No tmux session matches: $arg_name"
      exit 1
    fi
  fi

  # No name → show list to kill
  SESSION="$(
    tmux ls 2>/dev/null \
      | cut -d: -f1 \
      | fzf-tmux -p 60%,40% --prompt='Kill session > '
  )"

  [ -z "$SESSION" ] && exit 0

  tmux kill-session -t "$SESSION"
  exit 0
fi

# -----------------------------------------------------------
# INVALID ARG
# -----------------------------------------------------------
echo "Usage: tmux-sessionizer {open [name] | kill [name]}"
exit 1
