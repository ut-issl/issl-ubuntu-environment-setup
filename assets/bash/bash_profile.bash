# shellcheck shell=bash
# shellcheck disable=SC1091

issl_bootstrap_shell_home="${XDG_CONFIG_HOME:-$HOME/.config}/issl/shell"

if [[ -f "${issl_bootstrap_shell_home}/env.sh" ]]; then
  source "${issl_bootstrap_shell_home}/env.sh"
fi

# Ensure interactive login shells also load ~/.bashrc.
if [[ $- == *i* ]] && [[ -f "${HOME}/.bashrc" ]]; then
  source "${HOME}/.bashrc"
fi
