#!/usr/bin/env bash

# WALLPAPERS PATH
terminal=kitty
wallDIR="$HOME/lkasper-flake/wallpapers"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
wallpaper_current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"

# Directory for swaync
iDIR="$HOME/.config/swaync/images"

# swww transition config
FPS=60
TYPE="any"
DURATION=2
BEZIER=".43,1.19,1,.4"
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

# Collect wallpapers
mapfile -d '' PICS < <(find -L "${wallDIR}" -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o \
  -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.webp" -o \
  -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.mov" -o -iname "*.webm" \) -print0)

RANDOM_PIC="${PICS[$((RANDOM % ${#PICS[@]}))]}"
RANDOM_PIC_NAME="A Random wallpaper/video"

# Menu function (walker instead of rofi)
menu() {
  printf "%s\n" "$RANDOM_PIC_NAME"
  for pic_path in "${PICS[@]}"; do
    pic_name=$(basename "$pic_path")
    echo "${pic_name%.*}"
  done
}


# Main
main() {
  choice=$(menu | walker --dmenu)
  choice=$(echo "$choice" | xargs)

  if [[ -z "$choice" ]]; then
    echo "No choice selected. Exiting."
    exit 0
  fi

  if [[ "$choice" == "$RANDOM_PIC_NAME" ]]; then
    selected_file="$RANDOM_PIC"
  else
    selected_file=$(find "$wallDIR" -iname "$choice.*" -print -quit)
  fi

  echo $selected_file

  if [[ -z "$selected_file" ]]; then
    echo "File not found: $choice"
    exit 1
  fi

  if [[ "$selected_file" =~ \.(mp4|mkv|mov|webm)$ ]]; then
    pkill swww || true
    mpvpaper '*' -o "load-scripts=no no-audio --loop" "$selected_file" &
  else
    if ! pgrep -x "swww-daemon" >/dev/null; then
      swww-daemon --format xrgb &
    fi
    swww img "$selected_file" $SWWW_PARAMS
  fi
}

main
