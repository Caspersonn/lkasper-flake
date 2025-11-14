#!/usr/bin/env bash
input="/home/casper/Documents/AMS/AMS_logo_BIG.png"
out="/home/casper/Documents/AMS/AMS_logo_BIG_spin_50fps.gif"
fps=50        # practical max for GIF in browsers
seconds=3     # rotation duration

nix shell nixpkgs#imagemagick -c bash -lc '
set -euo pipefail
input="'"$input"'"; out="'"$out"'"; fps="'"$fps"'"; seconds="'"$seconds"'"
frames=$((fps*seconds))
delay=$((100/fps))   # centiseconds per frame (2 => 20ms)
workdir="$(mktemp -d)"

side=$(magick "$input" -format "%[fx:ceil(hypot(w,h))]" info:)
for i in $(seq 0 $((frames-1))); do
  angle=$(awk "BEGIN{print ($i*360)/$frames}")
  magick "$input" -background none -virtual-pixel none \
    -gravity center -extent ${side}x${side} \
    -distort SRT -"$angle" \
    -gravity center -extent ${side}x${side} \
    "$workdir/frame_$(printf "%04d" "$i").png"
done

magick -delay "$delay" -dispose previous -loop 0 "$workdir"/frame_*.png \
  -layers OptimizeTransparency "$out"

rm -rf "$workdir"
echo "Created: $out (frames='"$frames"', ~'"$fps"' fps)"
'
