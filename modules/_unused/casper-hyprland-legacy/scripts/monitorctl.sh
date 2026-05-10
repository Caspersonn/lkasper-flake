#!/usr/bin/env bash

# Grep the monitors and store their IDs in an array
mapfile -t monitors < <(hyprctl monitors all | grep "Monitor" | awk '{print $2}' | tr -d ',')

# Use walker to display a dmenu with all available options. Store user's selection in variable choice
choice=$(printf '%s\n' "${monitors[@]}" | walker --dmenu -H)

# If the user has selected an option, enable or disable it
if [[ -n $choice ]]; then
  # Ask the user if they want to enable or disable the monitor
  action=$(echo -e "Enable\nDisable" | walker --dmenu -H)

  # Enable or disable the chosen monitor
  if [[ $action == 'Enable' ]]; then
    hyprctl keyword monitor "$choice,enable"
  elif [[ $action == 'Disable' ]]; then
    hyprctl keyword monitor "$choice,disable"
  fi
fi
