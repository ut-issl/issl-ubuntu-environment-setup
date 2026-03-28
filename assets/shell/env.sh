# shellcheck shell=sh

export ISSL_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/issl"
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
  export PYTHONSTARTUP="${HOME}/.python/.pythonrc.py"
fi

if [ -z "${PYTHONHISTFILE:-}" ]; then
  export PYTHONHISTFILE="${HOME}/.python/.python_history"
fi
