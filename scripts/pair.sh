#!/usr/bin/env sh

set -eu

. "$(dirname -- "$0")/common.sh"

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  echo "usage: $0 <ip-or-host[:port]> <pin> [machine-type]" >&2
  echo "pairs and stores the machine as '$JURA_MACHINE_NAME'" >&2
  exit 2
fi

address=$1
pin=$2
machine_type=${3:-}

if [ -z "$machine_type" ] && [ -n "$JURA_MACHINE_TYPE" ]; then
  machine_type=$JURA_MACHINE_TYPE
fi

if [ -n "$machine_type" ]; then
  jura_cli pair "$address" --name "$JURA_MACHINE_NAME" --pin "$pin" \
    --machine-type "$machine_type"
  exit $?
fi

jura_cli pair "$address" --name "$JURA_MACHINE_NAME" --pin "$pin"
