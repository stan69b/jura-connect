#!/usr/bin/env sh

scripts_dir=$(
  CDPATH= cd -- "$(dirname -- "$0")" >/dev/null 2>&1 && pwd
) || exit 1
repo_root=$(
  CDPATH= cd -- "$scripts_dir/.." >/dev/null 2>&1 && pwd
) || exit 1

JURA_MACHINE_NAME=${JURA_MACHINE_NAME:-current}
JURA_STORE=${JURA_STORE:-}
JURA_MACHINE_TYPE=${JURA_MACHINE_TYPE:-}

if [ -x "$repo_root/.venv/bin/python3" ]; then
  JURA_PYTHON=${JURA_PYTHON:-"$repo_root/.venv/bin/python3"}
else
  JURA_PYTHON=${JURA_PYTHON:-python3}
fi

jura_cli() {
  if [ -n "$JURA_STORE" ]; then
    PYTHONPATH="$repo_root${PYTHONPATH:+:$PYTHONPATH}" \
      "$JURA_PYTHON" -m jura_connect --store "$JURA_STORE" "$@"
    return $?
  fi

  PYTHONPATH="$repo_root${PYTHONPATH:+:$PYTHONPATH}" \
    "$JURA_PYTHON" -m jura_connect "$@"
}
