#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
issl_config_home="${XDG_CONFIG_HOME:-$HOME/.config}/issl"
shared_git_config_path="${issl_config_home}/git/.gitconfig"
shared_bash_profile_path="${issl_config_home}/bash/.bash_profile"
shared_bashrc_path="${issl_config_home}/bash/.bashrc"
shared_zprofile_path="${issl_config_home}/zsh/.zprofile"
shared_zshrc_path="${issl_config_home}/zsh/.zshrc"
shared_rust_config_path="${issl_config_home}/rust/config.toml"
git_user_name="${GIT_USER_NAME-}"
git_user_email="${GIT_USER_EMAIL-}"
issl_enable_zsh="${ISSL_ENABLE_ZSH-}"
nix_feature_config="experimental-features = nix-command flakes"
hm_profile_dir="${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles"

# ===== Common ===== #

ensure_home_manager_profile_dir() {
  mkdir -p "${hm_profile_dir}"
}

prepend_block_once() {
  local file_path="$1"
  local begin_marker="$2"
  local end_marker="$3"
  local block_content="$4"
  local file_dir=""
  local temp_file=""

  file_dir="$(dirname "${file_path}")"
  mkdir -p "${file_dir}"
  touch "${file_path}"

  if grep -Fq "${begin_marker}" "${file_path}"; then
    return
  fi

  temp_file="$(mktemp)"
  {
    printf '%s\n' "${begin_marker}"
    printf '%s\n' "${block_content}"
    printf '%s\n' "${end_marker}"
    if [ -s "${file_path}" ]; then
      printf '\n'
      cat "${file_path}"
    fi
  } >"${temp_file}"
  mv "${temp_file}" "${file_path}"
}

is_yes() {
  case "${1-}" in
  y | Y | yes | YES | Yes | true | TRUE | True | 1) return 0 ;;
  *) return 1 ;;
  esac
}

is_no() {
  case "${1-}" in
  n | N | no | NO | No | false | FALSE | False | 0) return 0 ;;
  *) return 1 ;;
  esac
}

# ===== Bash ===== #

bash_profile_block() {
  printf '%s\n' \
    "if [ -f \"${shared_bash_profile_path}\" ]; then" \
    "  . \"${shared_bash_profile_path}\"" \
    "fi"
}

bashrc_block() {
  printf '%s\n' \
    "if [ -f \"${shared_bashrc_path}\" ]; then" \
    "  . \"${shared_bashrc_path}\"" \
    "fi"
}

ensure_bash_startup_files() {
  prepend_block_once \
    "${HOME}/.bash_profile" \
    "# >>> ISSL bash profile >>>" \
    "# <<< ISSL bash profile <<<" \
    "$(bash_profile_block)"
  prepend_block_once \
    "${HOME}/.bashrc" \
    "# >>> ISSL bash rc >>>" \
    "# <<< ISSL bash rc <<<" \
    "$(bashrc_block)"
}

# ===== Zsh ===== #

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

  current_shell_name="$(basename "${SHELL-}")"
  if [ "${current_shell_name}" = "zsh" ]; then
    return 0
  fi

  if [ ! -t 0 ]; then
    return 1
  fi

  read -r -p "Enable shared zsh configuration as well? [y/N] " response
  is_yes "${response}"
}

resolve_zdotdir_from_zshenv() {
  local zshenv_path="$1"
  local zsh_bin=""
  local resolved_value=""

  if [ -x "${HOME}/.nix-profile/bin/zsh" ]; then
    zsh_bin="${HOME}/.nix-profile/bin/zsh"
  elif command -v zsh >/dev/null 2>&1; then
    zsh_bin="$(command -v zsh)"
  else
    return 1
  fi

  resolved_value="$(
    env -i \
      HOME="${HOME}" \
      XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}" \
      ZDOTDIR=""
    # shellcheck disable=SC2016
    "${zsh_bin}" -c '
        . "$1"
        if [ -n "${ZDOTDIR:-}" ]; then
          print -r -- "${ZDOTDIR:A}"
        fi
      ' _ "${zshenv_path}"
  )"
  [ -n "${resolved_value}" ] || return 1
  printf '%s\n' "${resolved_value}"
}

zshenv_default_block() {
  cat <<'ZSHENV_EOF'
if [ -z "${ZDOTDIR:-}" ]; then
  export ZDOTDIR="$HOME/.zsh"
fi
ZSHENV_EOF
}

zprofile_block() {
  printf '%s\n' \
    "if [ -f \"${shared_zprofile_path}\" ]; then" \
    "  . \"${shared_zprofile_path}\"" \
    "fi"
}

zshrc_block() {
  printf '%s\n' \
    "if [ -f \"${shared_zshrc_path}\" ]; then" \
    "  . \"${shared_zshrc_path}\"" \
    "fi"
}

ensure_zsh_startup_files() {
  local zshenv_path="${HOME}/.zshenv"
  local zdotdir_path=""

  if [ -f "${zshenv_path}" ] && grep -Eq '^[[:space:]]*(export[[:space:]]+)?ZDOTDIR[[:space:]]*=' "${zshenv_path}"; then
    if ! zdotdir_path="$(resolve_zdotdir_from_zshenv "${zshenv_path}")"; then
      echo "Could not determine ZDOTDIR from ${zshenv_path}." >&2
      exit 1
    fi
  else
    prepend_block_once \
      "${zshenv_path}" \
      "# >>> ISSL zsh env >>>" \
      "# <<< ISSL zsh env <<<" \
      "$(zshenv_default_block)"
    zdotdir_path="${HOME}/.zsh"
  fi

  mkdir -p "${zdotdir_path}"
  prepend_block_once \
    "${zdotdir_path}/.zprofile" \
    "# >>> ISSL zsh profile >>>" \
    "# <<< ISSL zsh profile <<<" \
    "$(zprofile_block)"
  prepend_block_once \
    "${zdotdir_path}/.zshrc" \
    "# >>> ISSL zsh rc >>>" \
    "# <<< ISSL zsh rc <<<" \
    "$(zshrc_block)"
}

ensure_shell_listed_in_etc_shells() {
  local shell_path="$1"

  if grep -Fxq "${shell_path}" /etc/shells 2>/dev/null; then
    return 0
  fi

  if [ -w /etc/shells ]; then
    if printf '%s\n' "${shell_path}" >>/etc/shells; then
      return 0
    fi
    echo "warning: failed to append ${shell_path} to /etc/shells directly." >&2
  fi

  if command -v sudo >/dev/null 2>&1; then
    if printf '%s\n' "${shell_path}" | sudo tee -a /etc/shells >/dev/null; then
      return 0
    fi
    echo "warning: failed to add ${shell_path} to /etc/shells via sudo. Skipping login shell switch." >&2
    return 1
  fi

  echo "warning: /etc/shells is not writable and sudo is unavailable. Skipping login shell switch." >&2
  return 1
}

resolve_desired_zsh_path() {
  if [ -x "${HOME}/.nix-profile/bin/zsh" ]; then
    printf '%s\n' "${HOME}/.nix-profile/bin/zsh"
    return 0
  fi

  if command -v zsh >/dev/null 2>&1; then
    command -v zsh
    return 0
  fi

  return 1
}

current_login_shell() {
  if command -v getent >/dev/null 2>&1; then
    getent passwd "${USER}" | cut -d: -f7
    return 0
  fi

  if [ -n "${SHELL-}" ]; then
    printf '%s\n' "${SHELL}"
    return 0
  fi

  return 1
}

maybe_switch_login_shell_to_zsh() {
  local desired_zsh_path=""
  local active_login_shell=""
  local response=""

  if [ ! -t 0 ]; then
    echo "warning: skipping login shell switch prompt because this run is non-interactive." >&2
    return
  fi

  if ! desired_zsh_path="$(resolve_desired_zsh_path)"; then
    echo "warning: zsh binary not found while trying to switch login shell." >&2
    return
  fi

  active_login_shell="$(current_login_shell || true)"
  if [ -n "${active_login_shell}" ] && [ "${active_login_shell}" = "${desired_zsh_path}" ]; then
    return
  fi

  read -r -p "Switch your login shell to ${desired_zsh_path}? [y/N] " response
  if ! is_yes "${response}"; then
    return
  fi

  if ! ensure_shell_listed_in_etc_shells "${desired_zsh_path}"; then
    return
  fi

  if chsh -s "${desired_zsh_path}"; then
    echo "Updated login shell to ${desired_zsh_path}. This will apply to new login sessions."
  else
    echo "warning: failed to run chsh. You can retry manually with: chsh -s ${desired_zsh_path}" >&2
  fi
}

# ===== Git ===== #

ensure_git_include() {
  if ! git config --global --get-all include.path | grep -Fxq "${shared_git_config_path}"; then
    git config --global --add include.path "${shared_git_config_path}"
  fi
}

prompt_for_git_identity() {
  local git_name=""
  local git_email=""
  local missing_identity=0

  if ! git_name="$(git config --global --get user.name 2>/dev/null)" || [ -z "${git_name}" ]; then
    if [ -n "${git_user_name}" ]; then
      git_name="${git_user_name}"
    elif [ -t 0 ]; then
      read -r -p "Enter your full name for Git commits: " git_name
    else
      echo 'warning: Git user.name setup was skipped. Run with GIT_USER_NAME, or set it later with: git config --global user.name "Your Name"' >&2
      missing_identity=1
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
      echo 'warning: Git user.email setup was skipped. Run with GIT_USER_EMAIL, or set it later with: git config --global user.email "you@example.com"' >&2
      missing_identity=1
    fi
    if [ -n "${git_email}" ]; then
      git config --global user.email "${git_email}"
    fi
  fi

  if [ "${missing_identity}" = "1" ]; then
    echo "warning: Git identity was not configured. Environment variables were not provided, and this run is non-interactive so prompts could not be used. Pass the env vars, run interactively, or set it later." >&2
  fi
}

# ===== Python ===== #

pythonrc_block() {
  cat <<'PYTHON_EOF'
import os
from pathlib import Path
import runpy

issl_python_home = os.environ.get("ISSL_PYTHON_HOME")
if not issl_python_home:
  config_home = os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))
  issl_python_home = str(Path(config_home) / "issl" / "python")

shared_pythonrc = Path(issl_python_home) / "pythonrc.py"
if shared_pythonrc.is_file():
  runpy.run_path(str(shared_pythonrc), run_name="__main__")
PYTHON_EOF
}

ensure_python_startup_file() {
  prepend_block_once \
    "${HOME}/.python/.pythonrc.py" \
    "# >>> ISSL python startup >>>" \
    "# <<< ISSL python startup <<<" \
    "$(pythonrc_block)"
}

# ===== Rust ===== #

cargo_config_include_block() {
  printf '%s\n' \
    "include = [" \
    "  { path = \"${shared_rust_config_path}\", optional = true }," \
    "]"
}

ensure_cargo_config_include() {
  local cargo_home_path="${CARGO_HOME:-$HOME/.cargo}"
  local cargo_config_path="${cargo_home_path}/config.toml"

  mkdir -p "${cargo_home_path}"

  if [ -f "${cargo_config_path}" ] && grep -Fq "${shared_rust_config_path}" "${cargo_config_path}"; then
    return
  fi

  if [ -f "${cargo_config_path}" ] && grep -Eq '^[[:space:]]*include[[:space:]]*=' "${cargo_config_path}"; then
    echo "Skipping Cargo include setup because ${cargo_config_path} already defines include." >&2
    echo "Please add ${shared_rust_config_path} to include manually." >&2
    return
  fi

  prepend_block_once \
    "${cargo_config_path}" \
    "# >>> ISSL cargo config >>>" \
    "# <<< ISSL cargo config <<<" \
    "$(cargo_config_include_block)"
}

ensure_rustup_default_stable() {
  if ! command -v rustup >/dev/null 2>&1; then
    echo "rustup is required before configuring the Rust toolchain." >&2
    exit 1
  fi

  if ! rustup show active-toolchain >/dev/null 2>&1; then
    rustup toolchain install stable
  fi

  if ! rustup show active-toolchain | grep -Eq '^stable(-|$)'; then
    rustup default stable
  fi
}

if ! command -v nix >/dev/null 2>&1; then
  echo "nix is required before running scripts/apply.sh." >&2
  exit 1
fi

if [ -n "${NIX_CONFIG-}" ]; then
  export NIX_CONFIG="${NIX_CONFIG}"$'\n'"${nix_feature_config}"
else
  export NIX_CONFIG="${nix_feature_config}"
fi

current_system="$(
  nix --accept-flake-config --extra-experimental-features "nix-command flakes" \
    eval --impure --raw --expr builtins.currentSystem
)"

ensure_home_manager_profile_dir
if should_enable_zsh; then
  home_configuration_name="issl-common-zsh-${current_system}"
  zsh_enabled=1
else
  home_configuration_name="issl-common-${current_system}"
  zsh_enabled=0
fi

nix --accept-flake-config --extra-experimental-features "nix-command flakes" run "${repo_root}#home-manager" -- \
  switch --flake "${repo_root}#${home_configuration_name}" --impure

ensure_bash_startup_files
if [ "${zsh_enabled}" = "1" ]; then
  ensure_zsh_startup_files
  maybe_switch_login_shell_to_zsh
fi
ensure_git_include
prompt_for_git_identity
ensure_python_startup_file
ensure_cargo_config_include
ensure_rustup_default_stable

echo "Applied the shared Home Manager configuration."
