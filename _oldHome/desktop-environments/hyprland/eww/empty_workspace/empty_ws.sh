#!/usr/bin/env bash

# Replace with the monitor you want
MONITOR=0

while true; do
    # Get the number of windows in the current workspace
    WIN_COUNT=$(hyprctl activeworkspace -j | jq '.windows | length')

    if [[ "$WIN_COUNT" -eq 0 ]]; then
        # Open Eww dashboard if no windows
        eww open empty_dashboard
    else
        # Close it if windows are present
        eww close empty_dashboard
    fi

    sleep 0.1
done
