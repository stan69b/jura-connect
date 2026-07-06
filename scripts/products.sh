#!/usr/bin/env sh

set -eu

. "$(dirname -- "$0")/common.sh"

if [ "$#" -ne 0 ]; then
  echo "usage: $0" >&2
  echo "lists brewable products for '$JURA_MACHINE_NAME'" >&2
  exit 2
fi

if [ -n "$JURA_MACHINE_TYPE" ]; then
  jura_cli command --name "$JURA_MACHINE_NAME" \
    --machine-type "$JURA_MACHINE_TYPE" products
  exit $?
fi

jura_cli command --name "$JURA_MACHINE_NAME" products
