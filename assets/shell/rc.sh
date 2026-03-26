# shellcheck shell=sh

# ===== Aliases ===== #

# Configure GNU-style color output for common tools when available.
if command -v dircolors >/dev/null 2>&1; then
  # Prefer ~/.dircolors, then the shared ISSL file.
  issl_dircolors_path="${XDG_CONFIG_HOME:-$HOME/.config}/issl/shell/.dircolors"
  if [ -r "${HOME}/.dircolors" ]; then
    eval "$(dircolors -b "${HOME}/.dircolors")"
  elif [ -r "${issl_dircolors_path}" ]; then
    eval "$(dircolors -b "${issl_dircolors_path}")"
  else
    # Fall back to system default LS_COLORS.
    eval "$(dircolors -b)"
  fi

  alias ls='ls --color=auto'       # Colorize directory listings.
  alias dir='dir --color=auto'     # Colorize dir output.
  alias vdir='vdir --color=auto'   # Colorize verbose dir output.
  alias grep='grep --color=auto'   # Highlight grep matches.
  alias fgrep='fgrep --color=auto' # Highlight fixed-string grep matches.
  alias egrep='egrep --color=auto' # Highlight extended-regex grep matches.
fi

alias rm='rm -i' # Ask before file removal.
alias mv='mv -i' # Ask before overwrite on move.
alias cp='cp -i' # Ask before overwrite on copy.

alias ll='ls -lhF'   # Long list with human-readable sizes.
alias la='ls -A'     # Show all except . and ...
alias lla='ls -lhFA' # Long list including hidden files except . and ...
alias lr='ls -R'     # Recursive listing.

# Use colordiff when available, otherwise keep unified diff output.
if command -v colordiff >/dev/null 2>&1; then
  alias diff='colordiff -u' # Unified diff with color.
else
  alias diff='diff -u' # Unified diff without color.
fi

# ===== Functions ===== #

man() {
  env \
    LESS_TERMCAP_md="$(printf '\033[01;36m')" \
    LESS_TERMCAP_me="$(printf '\033[0m')" \
    LESS_TERMCAP_us="$(printf '\033[01;32m')" \
    LESS_TERMCAP_ue="$(printf '\033[0m')" \
    LESS_TERMCAP_so="$(printf '\033[45;93m')" \
    LESS_TERMCAP_se="$(printf '\033[0m')" \
    command man "$@"
}
