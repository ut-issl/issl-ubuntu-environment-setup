#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
shared_git_config_path="${XDG_CONFIG_HOME:-$HOME/.config}/issl/git/.gitconfig"
git_user_name="${GIT_USER_NAME:-}"
git_user_email="${GIT_USER_EMAIL:-}"
issl_enable_zsh="${ISSL_ENABLE_ZSH:-}"
nix_feature_config="experimental-features = nix-command flakes"
hm_profile_dir="${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles"

ensure_git_include() {
  if ! git config --global --get-all include.path | grep -Fxq "${shared_git_config_path}"; then
    git config --global --add include.path "${shared_git_config_path}"
  fi
}

prompt_for_git_identity() {
  local git_name=""
  local git_email=""

  if ! git_name="$(git config --global --get user.name 2>/dev/null)" || [ -z "${git_name}" ]; then
    if [ -n "${git_user_name}" ]; then
      git_name="${git_user_name}"
    elif [ -t 0 ]; then
      read -r -p "Enter your full name for Git commits: " git_name
    else
      echo "user.name is not set; provide GIT_USER_NAME or run interactively." >&2
      exit 1
    fi
    if [ -n "${git_name}" ]; then
      git config --global user.name "${git_name}"
    fi
  fi

  if ! git_email="$(git config --global --get user.email 2>/dev/null)" || [ -z "${git_email}" ]; then
    if [ -n "${git_user_email}" ]; then
      git_email="${git_user_email}"
    elif [ -t 0 ]; then
      read -r -p "Enter your email address for Git commits: " git_email
    else
      echo "user.email is not set; provide GIT_USER_EMAIL or run interactively." >&2
      exit 1
    fi
    if [ -n "${git_email}" ]; then
      git config --global user.email "${git_email}"
    fi
  fi
}

ensure_home_manager_profile_dir() {
  mkdir -p "${hm_profile_dir}"
}

is_yes() {
  case "${1:-}" in
  y | Y | yes | YES | Yes | true | TRUE | True | 1) return 0 ;;
  *) return 1 ;;
  esac
}

is_no() {
  case "${1:-}" in
  n | N | no | NO | No | false | FALSE | False | 0) return 0 ;;
  *) return 1 ;;
  esac
}

should_enable_zsh() {
  local current_shell_name=""
  local response=""

  if [ -n "${issl_enable_zsh}" ]; then
    if is_yes "${issl_enable_zsh}"; then
      return 0
    fi
    if is_no "${issl_enable_zsh}"; then
      return 1
    fi
    echo "ISSL_ENABLE_ZSH must be a yes/no style value." >&2
    exit 1
  fi

  current_shell_name="$(basename "${SHELL:-}")"
  if [ "${current_shell_name}" = "zsh" ]; then
    return 0
  fi

  if [ ! -t 0 ]; then
    return 1
  fi

  read -r -p "Enable shared zsh configuration as well? [y/N] " response
  is_yes "${response}"
}

if ! command -v nix >/dev/null 2>&1; then
  echo "nix is required before running scripts/apply.sh." >&2
  exit 1
fi

if [ -n "${NIX_CONFIG:-}" ]; then
  export NIX_CONFIG="${NIX_CONFIG}"$'\n'"${nix_feature_config}"
else
  export NIX_CONFIG="${nix_feature_config}"
fi

current_system="$(
  nix --accept-flake-config --extra-experimental-features "nix-command flakes" \
    eval --impure --raw --expr builtins.currentSystem
)"
home_configuration_name="issl-common-${current_system}"

ensure_home_manager_profile_dir
if should_enable_zsh; then
  export ISSL_ENABLE_ZSH=1
else
  export ISSL_ENABLE_ZSH=0
fi

nix --accept-flake-config --extra-experimental-features "nix-command flakes" run "${repo_root}#home-manager" -- \
  switch --flake "${repo_root}#${home_configuration_name}" --impure

ensure_git_include
prompt_for_git_identity

echo "Applied the shared Home Manager configuration."
