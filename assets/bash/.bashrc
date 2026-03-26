# shellcheck shell=sh
# shellcheck disable=SC1091

if [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/issl/shell/env.sh" ]; then
  . "${XDG_CONFIG_HOME:-$HOME/.config}/issl/shell/env.sh"
fi

if [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/issl/shell/rc.sh" ]; then
  . "${XDG_CONFIG_HOME:-$HOME/.config}/issl/shell/rc.sh"
fi

# Enable bash completion from Home Manager profile when available.
if [ -f "${HOME}/.nix-profile/share/bash-completion/bash_completion" ]; then
  . "${HOME}/.nix-profile/share/bash-completion/bash_completion"
elif [ -f "/etc/bash_completion" ]; then
  . "/etc/bash_completion"
fi
