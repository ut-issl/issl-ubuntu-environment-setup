# shellcheck shell=sh
# shellcheck disable=SC1091

if [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/issl/shell/env.sh" ]; then
  . "${XDG_CONFIG_HOME:-$HOME/.config}/issl/shell/env.sh"
fi

if [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/issl/shell/rc.sh" ]; then
  . "${XDG_CONFIG_HOME:-$HOME/.config}/issl/shell/rc.sh"
fi

# ===== History ===== #

export HISTFILE="${ZDOTDIR}/.zsh_history"  # Store history under the active ZDOTDIR.
export HISTSIZE=1000                       # Keep up to 1000 commands in memory.
export SAVEHIST=10000                      # Persist up to 10000 commands to HISTFILE.

setopt append_history        # Append history entries instead of overwriting the file.
setopt extended_history      # Record execution timestamps in history entries.
setopt hist_ignore_all_dups  # Remove older duplicates when a command repeats.
setopt hist_ignore_space     # Skip commands that start with a space.
setopt hist_reduce_blanks    # Compress redundant internal whitespace before saving.
setopt share_history         # Share history across concurrent zsh sessions.
