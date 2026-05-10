#!/usr/bin/env bash

config_file=~/.config/hypr/hyprland.conf
keybinds=$(grep -oP '(?<=bind=).*' "$config_file" |
  sed 's/,\([^,]*\)$/ = \1/' |
  sed 's/, exec//g' |
  sed 's/^,//g')

# Pass the keybinds as input to walker
#echo "$keybinds" | walker --dmenu
echo "$keybinds" | walker --dmenu -H

