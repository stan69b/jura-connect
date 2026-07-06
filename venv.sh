#!/usr/bin/env sh

sourced=0
if [ -n "${ZSH_VERSION:-}" ]; then
  case $ZSH_EVAL_CONTEXT in
    *:file) sourced=1 ;;
  esac
elif [ -n "${BASH_VERSION:-}" ]; then
  if [ "${BASH_SOURCE[0]}" != "$0" ]; then
    sourced=1
  fi
fi

jura_connect_set_paths() {
  if [ -n "${ZSH_VERSION:-}" ]; then
    script_path=$(eval 'printf "%s" "${(%):-%N}"')
  else
    script_path="${BASH_SOURCE[0]:-$0}"
  fi

  script_dir=$(
    CDPATH= cd -- "$(dirname -- "$script_path")" >/dev/null 2>&1 && pwd
  ) || {
    echo "Could not determine the repository directory." >&2
    return 1
  }

  venv_dir="$script_dir/.venv"
  activate_script="$venv_dir/bin/activate"
}

jura_connect_prepare_venv() {
  jura_connect_set_paths || return 1

  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required to create the virtual environment." >&2
    return 1
  fi

  if [ ! -d "$venv_dir" ]; then
    echo "Creating virtual environment in $venv_dir"
    python3 -m venv "$venv_dir" || return 1
  elif [ ! -f "$activate_script" ]; then
    echo "Found $venv_dir but it does not look like a valid virtual environment." >&2
    echo "Remove it and re-run '. ./venv.sh' to recreate it." >&2
    return 1
  else
    echo "Reusing virtual environment in $venv_dir"
  fi
}

jura_connect_activate_current_shell() {
  if [ "$sourced" -ne 1 ]; then
    echo "This helper must be sourced to activate the venv in your current shell." >&2
    echo "Use: . ./venv.sh" >&2
    return 1
  fi

  jura_connect_prepare_venv || return 1

  # shellcheck disable=SC1090
  . "$activate_script" || return 1

  echo "Activated $(basename "$venv_dir")"
  python3 --version
  pip3 --version
}

jura_connect_launch_subshell() {
  jura_connect_prepare_venv || return 1

  shell_path="${SHELL:-}"
  if [ -z "$shell_path" ] || [ ! -x "$shell_path" ]; then
    echo "Could not determine your login shell. Source '. ./venv.sh' instead." >&2
    return 1
  fi

  shell_name=$(basename -- "$shell_path")

  case "$shell_name" in
    zsh)
      temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/jura-connect-venv-zsh.XXXXXX") || return 1
      temp_zshenv="$temp_dir/.zshenv"
      temp_zshrc="$temp_dir/.zshrc"

      cat >"$temp_zshenv" <<EOF
[ -f "\$HOME/.zshenv" ] && . "\$HOME/.zshenv"
EOF

      cat >"$temp_zshrc" <<EOF
autoload -Uz compinit
compinit -i
[ -f "\$HOME/.zshrc" ] && . "\$HOME/.zshrc"
. "$activate_script"
echo "Activated $(basename "$venv_dir") in a subshell. Run 'exit' to leave it."
TRAPEXIT() {
  command rm -rf -- "$temp_dir"
}
EOF

      exec env ZDOTDIR="$temp_dir" "$shell_path" -i
      ;;
    bash)
      temp_rc=$(mktemp "${TMPDIR:-/tmp}/jura-connect-venv-bash.XXXXXX") || return 1

      cat >"$temp_rc" <<EOF
[ -f "\$HOME/.bashrc" ] && . "\$HOME/.bashrc"
. "$activate_script"
echo "Activated $(basename "$venv_dir") in a subshell. Run 'exit' to leave it."
trap 'rm -f -- "$temp_rc"' EXIT
EOF

      exec "$shell_path" --rcfile "$temp_rc" -i
      ;;
    *)
      echo "Executing this helper directly is only supported for bash and zsh." >&2
      echo "Use '. ./venv.sh' to activate the venv in your current shell." >&2
      return 1
      ;;
  esac
}

if [ "$sourced" -eq 1 ]; then
  jura_connect_activate_current_shell
  return $?
fi

jura_connect_launch_subshell
exit_code=$?

exit "$exit_code"
