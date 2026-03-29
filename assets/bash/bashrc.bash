# shellcheck shell=bash
# shellcheck disable=SC1091

if [[ ${ISSL_BASHRC_LOADED:-0} == "1" ]]; then
  return 0
fi
export ISSL_BASHRC_LOADED=1

issl_bootstrap_shell_home="${XDG_CONFIG_HOME:-$HOME/.config}/issl/shell"

if [[ -f "${issl_bootstrap_shell_home}/rc.sh" ]]; then
  source "${issl_bootstrap_shell_home}/rc.sh"
fi

# ===== Completion ===== #

# Enable bash completion from Home Manager profile when available.
if [[ -f "${ISSL_NIX_PROFILE_PATH}/share/bash-completion/bash_completion" ]]; then
  source "${ISSL_NIX_PROFILE_PATH}/share/bash-completion/bash_completion"
elif [[ -f "/etc/bash_completion" ]]; then
  source "/etc/bash_completion"
fi

# Enable uv completion when uv is available.
if command -v uv >/dev/null 2>&1; then
  if uv generate-shell-completion bash >/dev/null 2>&1; then
    eval "$(uv generate-shell-completion bash)"
  fi
fi

# Enable rustup/cargo completion when rustup is available.
if command -v rustup >/dev/null 2>&1; then
  eval "$(rustup completions bash)"
  if rustup completions bash cargo >/dev/null 2>&1; then
    eval "$(rustup completions bash cargo)"
  fi
fi
