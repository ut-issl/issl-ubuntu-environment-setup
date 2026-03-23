# shellcheck shell=sh

issl_config_home="${XDG_CONFIG_HOME:-$HOME/.config}/issl"
export ISSL_CONFIG_HOME="${issl_config_home}"

issl_prepend_path() {
  [ "$#" -eq 1 ] || return 0
  [ -d "$1" ] || return 0

  case ":${PATH}:" in
  *:"$1":*) ;;
  *) PATH="$1${PATH:+:$PATH}" ;;
  esac
}
