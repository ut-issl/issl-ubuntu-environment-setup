# shellcheck shell=sh
# shellcheck disable=SC1091

issl_bootstrap_shell_home="${XDG_CONFIG_HOME:-$HOME/.config}/issl/shell"

if [ -f "${issl_bootstrap_shell_home}/env.sh" ]; then
  . "${issl_bootstrap_shell_home}/env.sh"
fi
