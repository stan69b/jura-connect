#!/usr/bin/env sh

set -eu

. "$(dirname -- "$0")/common.sh"

if [ "$#" -lt 1 ]; then
  echo "usage: $0 <product> [param=value ...]" >&2
  echo "example: $0 espresso strength=7 water=35" >&2
  exit 2
fi

product=$1
shift

if [ -n "$JURA_MACHINE_TYPE" ]; then
  jura_cli command --name "$JURA_MACHINE_NAME" \
    --machine-type "$JURA_MACHINE_TYPE" \
    --allow-destructive-commands brew "$product" "$@"
  exit $?
fi

jura_cli command --name "$JURA_MACHINE_NAME" \
  --allow-destructive-commands brew "$product" "$@"
