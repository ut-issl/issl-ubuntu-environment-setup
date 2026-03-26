# shellcheck shell=sh
# shellcheck disable=SC1091

if [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/issl/shell/env.sh" ]; then
  . "${XDG_CONFIG_HOME:-$HOME/.config}/issl/shell/env.sh"
fi
