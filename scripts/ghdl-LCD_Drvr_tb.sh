#!/bin/bash
set -eEu -o pipefail
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$SCRIPT_DIR/.."
VHD_FILES=$(find "$ROOT_DIR" -type f \( -name "*.vhd" -o -name "*.vhdl" \) )
WARNINGS="--warn-library --warn-default-binding --warn-binding --warn-reserved \
--warn-nested-comment --warn-parenthesis --warn-vital-generic --warn-delayed-checks \
--warn-body --warn-specs --warn-runtime-error --warn-shared --warn-hide --warn-unused \
--warn-others --warn-pure --warn-static" # --warn-error

rm -rf "$ROOT_DIR"/work
mkdir "$ROOT_DIR"/work

echo "Import all files"
"$SCRIPT_DIR/ghdl.sh" import --workdir="$ROOT_DIR"/work --std=08 "$WARNINGS" "$VHD_FILES"

echo "Analyse, elaborate, and make all imported files"
"$SCRIPT_DIR/ghdl.sh" make   --workdir="$ROOT_DIR"/work --std=08 "$WARNINGS" LCD_Drvr_tb

echo "Running testbench"
"$SCRIPT_DIR/ghdl.sh" run    --workdir="$ROOT_DIR"/work --std=08 "$WARNINGS" LCD_Drvr_tb \
    --stats --assert-level=warning --wave=LCD_Drvr_tb.ghw
