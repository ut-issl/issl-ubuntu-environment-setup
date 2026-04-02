# shellcheck shell=sh
# shellcheck disable=SC1091

if [ "${ISSL_ZSHRC_LOADED:-0}" = "1" ]; then
  return 0
fi
export ISSL_ZSHRC_LOADED=1

issl_bootstrap_shell_home="${XDG_CONFIG_HOME:-$HOME/.config}/issl/shell"

if [ -f "${issl_bootstrap_shell_home}/rc.sh" ]; then
  . "${issl_bootstrap_shell_home}/rc.sh"
fi

# ===== History ===== #

export HISTFILE="${ZDOTDIR}/.zsh_history" # Store history under the active ZDOTDIR.
export HISTSIZE=1000                      # Keep up to 1000 commands in memory.
export SAVEHIST=10000                     # Persist up to 10000 commands to HISTFILE.

setopt append_history       # Append history entries instead of overwriting the file.
setopt extended_history     # Record execution timestamps in history entries.
setopt hist_ignore_all_dups # Remove older duplicates when a command repeats.
setopt hist_ignore_space    # Skip commands that start with a space.
setopt hist_reduce_blanks   # Compress redundant internal whitespace before saving.
setopt share_history        # Share history across concurrent zsh sessions.

# ===== Completion ===== #

# Add $ZDOTDIR/functions to fpath for user-managed functions and completions.
issl_zsh_functions_dir="${ZDOTDIR}/functions"
if [ ! -d "${issl_zsh_functions_dir}" ]; then
  mkdir -p "${issl_zsh_functions_dir}" 2>/dev/null || true
fi
if [ -d "${issl_zsh_functions_dir}" ]; then
  # shellcheck disable=SC3030,SC3054
  fpath=("${issl_zsh_functions_dir}" "${fpath[@]}")
fi

# Make toolchain-provided cargo completion discoverable by compinit.
if command -v rustc >/dev/null 2>&1; then
  issl_rustup_cargo_completion_dir="$(rustc --print sysroot 2>/dev/null)/share/zsh/site-functions"
  if [ -f "${issl_rustup_cargo_completion_dir}/_cargo" ]; then
    # shellcheck disable=SC3030,SC3054
    fpath=("${issl_rustup_cargo_completion_dir}" "${fpath[@]}")
  fi
fi

# shellcheck disable=SC3044
autoload -Uz compinit
compinit

# Enable uv completion when uv is available.
if command -v uv >/dev/null 2>&1; then
  if uv generate-shell-completion zsh >/dev/null 2>&1; then
    eval "$(uv generate-shell-completion zsh)"
  fi
fi

# Enable rustup completion when rustup is available.
if command -v rustup >/dev/null 2>&1; then
  eval "$(rustup completions zsh)"
fi
