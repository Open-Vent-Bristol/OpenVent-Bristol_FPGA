#!/bin/bash
set -eEu -o pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  docker kill gtkwave
}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR=$SCRIPT_DIR/..
ARGS=( $@ )

echo "[$PWD]$ gtkwave ${ARGS[@]}"
echo "Open gtkwave in a browser http://localhost:8080"

docker run \
    --detach \
    --interactive \
    --tty \
    --publish 8080:8080 \
    --name gtkwave \
    --rm \
    --volume "$ROOT_DIR:$ROOT_DIR" \
    --workdir "$ROOT_DIR" \
    ghdl/ext:latest \
        broadwayd

docker exec \
    --interactive \
    --tty \
    gtkwave \
        gtkwave --nomenus "${ARGS[@]}"
