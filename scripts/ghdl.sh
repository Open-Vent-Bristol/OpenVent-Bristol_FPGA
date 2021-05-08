#!/bin/bash
set -eEu -o pipefail
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR=$SCRIPT_DIR/..
ARGS=( $@ )

echo "[$PWD]$ ghdl ${ARGS[@]}"

exec docker run \
    --interactive \
    --tty \
    --name ghdl \
    --rm \
    --volume "$ROOT_DIR:$ROOT_DIR" \
    --workdir "$PWD" \
    ghdl/ext:latest \
        ghdl "${ARGS[@]}"
