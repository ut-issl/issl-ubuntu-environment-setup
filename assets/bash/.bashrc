# shellcheck shell=bash
# shellcheck disable=SC1091

issl_bootstrap_shell_home="${XDG_CONFIG_HOME:-$HOME/.config}/issl/shell"

if [[ -f "${issl_bootstrap_shell_home}/rc.sh" ]]; then
  source "${issl_bootstrap_shell_home}/rc.sh"
fi

# Enable bash completion from Home Manager profile when available.
if [[ -f "${ISSL_NIX_PROFILE_PATH}/share/bash-completion/bash_completion" ]]; then
  source "${ISSL_NIX_PROFILE_PATH}/share/bash-completion/bash_completion"
elif [[ -f "/etc/bash_completion" ]]; then
  source "/etc/bash_completion"
fi
