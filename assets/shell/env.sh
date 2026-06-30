# shellcheck shell=sh

if [ "${ISSL_ENV_SH_LOADED:-0}" = "1" ]; then
  return 0
fi
export ISSL_ENV_SH_LOADED=1

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

export ISSL_CONFIG_HOME="${XDG_CONFIG_HOME}/issl"
export ISSL_SHELL_HOME="${ISSL_CONFIG_HOME}/shell"
export ISSL_PYTHON_HOME="${ISSL_CONFIG_HOME}/python"
export ISSL_RUST_HOME="${ISSL_CONFIG_HOME}/rust"

export ISSL_NIX_PROFILE_PATH="${ISSL_NIX_PROFILE_PATH:-$HOME/.nix-profile}"
export CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"

# Prepend one existing directory to PATH if it is not already present.
prepend_path() {
  [ "$#" -eq 1 ] || return 0
  [ -d "$1" ] || return 0

  case ":${PATH}:" in
  *:"$1":*) ;;
  *) PATH="$1${PATH:+:$PATH}" ;;
  esac
}

prepend_path "$HOME/.local/bin"
prepend_path "${CARGO_HOME}/bin"

# ===== Python ===== #

if [ -z "${PYTHONSTARTUP:-}" ]; then
  export PYTHONSTARTUP="${XDG_CONFIG_HOME}/python/pythonrc.py"
fi

if [ -z "${PYTHONHISTFILE:-}" ]; then
  export PYTHONHISTFILE="${XDG_STATE_HOME}/python/python_history"
fi
