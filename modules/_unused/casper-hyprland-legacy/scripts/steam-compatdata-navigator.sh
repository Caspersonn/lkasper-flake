#!/usr/bin/env bash
set -euo pipefail

STEAM_DIR="$HOME/.steam/steam"
STEAM_APPS_MAIN="$STEAM_DIR/steamapps"
LIBRARY_FOLDERS_FILE="$STEAM_APPS_MAIN/libraryfolders.vdf"

command -v fzf >/dev/null || { echo "fzf required"; exit 1; }

LIB_DIRS=("$STEAM_APPS_MAIN")
[[ -f "$LIBRARY_FOLDERS_FILE" ]] &&
  while IFS= read -r p; do
    path=$(echo "$p" | sed -E 's/.*"path"[[:space:]]*"([^"]+)".*/\1/')
    [[ -d "$path/steamapps" ]] && LIB_DIRS+=("$path/steamapps")
  done < <(grep '"path"' "$LIBRARY_FOLDERS_FILE")

declare -A games=() paths=()
for lib in "${LIB_DIRS[@]}"; do
  label=$(basename "$(dirname "$lib")") # show drive/folder name
  for acf in "$lib"/*.acf; do
    [[ -f "$acf" ]] || continue
    appid=$(grep -m1 '"appid"' "$acf" | awk -F '"' '{print $4}' || true)
    name=$(grep -m1 '"name"' "$acf" | awk -F '"' '{print $4}' || true)
    [[ -n "${appid:-}" && -n "${name:-}" ]] || continue
    key="$name [$label]"
    games["$key"]=$appid
    paths["$appid"]="$lib/compatdata/$appid"
  done
done

(( ${#games[@]} == 0 )) && { echo "No installed Steam games found."; exit 1; }

choice=$(printf '%s\n' "${!games[@]}" | sort | fzf --prompt="Select a Steam game: ") || exit 0
appid=${games[$choice]}
target=${paths[$appid]}

if [[ -d "$target" ]]; then
  echo "Opening compatdata folder for ${choice% *} (App ID: $appid)"
  command -v xdg-open >/dev/null && xdg-open "$target" >/dev/null 2>&1 &
else
  echo "Compatdata folder not found for ${choice% *} (App ID: $appid)."
fi
