#!/bin/bash
set -eEu -o pipefail
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$SCRIPT_DIR/.."
VHD_FILES=$(find "$ROOT_DIR" -type f \( -name "*.vhd" -o -name "*.vhdl" \) )

rm -rf "$ROOT_DIR"/work
mkdir "$ROOT_DIR"/work
# Import all files
"$SCRIPT_DIR/ghdl.sh" import --workdir="$ROOT_DIR"/work --std=08 "$VHD_FILES"
# Analyse,elaborate, and make all imported files
# "$ROOT_DIR/ghdl.sh" -m --workdir="$ROOT_DIR/work"
