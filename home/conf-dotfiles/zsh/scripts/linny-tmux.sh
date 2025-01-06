#!/bin/sh
tmux new-session -d 'linny'
tmux split-window -h
tmux new-window 'mutt'
tmux -2 attach-session -d
