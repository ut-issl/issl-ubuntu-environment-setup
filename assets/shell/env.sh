# shellcheck shell=sh

export ISSL_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/issl"

# Prepend one existing directory to PATH if it is not already present.
prepend_path() {
  [ "$#" -eq 1 ] || return 0
  [ -d "$1" ] || return 0

  case ":${PATH}:" in
  *:"$1":*) ;;
  *) PATH="$1${PATH:+:$PATH}" ;;
  esac
}
