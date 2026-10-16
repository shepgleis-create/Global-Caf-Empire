#!/usr/bin/env bash
set -euo pipefail
# Reproducible Godot 4.4.1 native HTML5 export. No HTML game recreation.
VERSION="4.4.1"
RUNTIME_URL="https://github.com/godotengine/godot/releases/download/${VERSION}-stable/Godot_v${VERSION}-stable_linux.x86_64.zip"
TEMPLATE_URL="https://github.com/godotengine/godot/releases/download/${VERSION}-stable/Godot_v${VERSION}-stable_export_templates.tpz"
mkdir -p .build/godot .build/templates web
if [ ! -f .build/godot/Godot_v${VERSION}-stable_linux.x86_64 ]; then
  curl -fsSL --retry 3 -o .build/godot/linux.zip "$RUNTIME_URL"
  unzip -oq .build/godot/linux.zip -d .build/godot
  chmod +x .build/godot/Godot_v${VERSION}-stable_linux.x86_64
fi
TEMPLATE_DIR="$HOME/.local/share/godot/export_templates/${VERSION}.stable"
mkdir -p "$TEMPLATE_DIR"
if [ ! -f "$TEMPLATE_DIR/web_nothreads_release.zip" ]; then
  curl -fsSL --retry 3 -o .build/templates/export_templates.tpz "$TEMPLATE_URL"
  unzip -joq .build/templates/export_templates.tpz templates/web_nothreads_release.zip templates/web_nothreads_debug.zip templates/version.txt -d "$TEMPLATE_DIR"
fi
ENGINE=".build/godot/Godot_v${VERSION}-stable_linux.x86_64"
"$ENGINE" --headless --editor --path . --quit
"$ENGINE" --headless --path . --export-release Web web/index.html
test -s web/index.html
test -s web/index.wasm
test -s web/index.pck
echo "Native Godot WebAssembly export verified: $(du -h web/index.wasm | awk '{print $1}')"
