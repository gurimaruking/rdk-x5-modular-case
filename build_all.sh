#!/usr/bin/env bash
# Build all STLs and preview images for rdk-x5-modular-case
set -euo pipefail

# Detect OpenSCAD binary (Linux/macOS/WSL)
if command -v openscad >/dev/null 2>&1; then
    OPENSCAD=openscad
elif [ -x "/c/Program Files/OpenSCAD/openscad.exe" ]; then
    OPENSCAD="/c/Program Files/OpenSCAD/openscad.exe"
else
    echo "OpenSCAD not found. Install from https://openscad.org/" >&2
    exit 1
fi

cd "$(dirname "$0")"
mkdir -p stl images

declare -a TARGETS=(
    "case_base:1"
    "lid_default:2"
    "lid_open:3"
    "lid_vesa:4"
)

for t in "${TARGETS[@]}"; do
    name="${t%%:*}"
    show="${t##*:}"
    echo "[$name] STL..."
    "$OPENSCAD" -o "stl/$name.stl"   -D "SHOW=$show" rdk_x5_case.scad
    echo "[$name] PNG..."
    "$OPENSCAD" -o "images/$name.png" --imgsize=1000,800 --colorscheme=Tomorrow -D "SHOW=$show" rdk_x5_case.scad
done

echo "[assembly] PNG..."
"$OPENSCAD" -o "images/assembly_preview.png" --imgsize=1200,900 --colorscheme=Tomorrow -D "SHOW=0" rdk_x5_case.scad

echo
echo "Done."
ls -la stl/ images/
