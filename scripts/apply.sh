#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=scripts/bootstrap-host.sh
. "${repo_root}/scripts/bootstrap-host.sh"

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

issl_config_home="${XDG_CONFIG_HOME}/issl"
shared_nix_config_path="${issl_config_home}/nix/nix.conf"
shared_shell_env_path="${issl_config_home}/shell/env.sh"
shared_bashrc_path="${issl_config_home}/bash/.bashrc"
shared_zprofile_path="${issl_config_home}/zsh/.zprofile"
shared_zshrc_path="${issl_config_home}/zsh/.zshrc"
shared_git_config_path="${issl_config_home}/git/.gitconfig"
shared_rust_config_path="${issl_config_home}/rust/config.toml"
git_user_name="${GIT_USER_NAME-}"
git_user_email="${GIT_USER_EMAIL-}"
issl_enable_zsh="${ISSL_ENABLE_ZSH-}"
nix_feature_config="experimental-features = nix-command flakes"
hm_profile_dir="${XDG_STATE_HOME}/nix/profiles"

# ===== Common ===== #

ensure_home_manager_profile_dir() {
  mkdir -p "${hm_profile_dir}"
}

is_nix_store_symlink() {
  local path="$1"
  local resolved_path=""

  [ -L "${path}" ] || return 1
  resolved_path="$(readlink -f "${path}")" || return 1
  case "${resolved_path}" in
  /nix/store/*) return 0 ;;
  *) return 1 ;;
  esac
}

guard_against_existing_home_manager_files() {
  local zdotdir_path="${ZDOTDIR:-${XDG_CONFIG_HOME}/zsh}"
  local cargo_home_path="${CARGO_HOME:-$HOME/.cargo}"
  local candidate_path=""
  local managed_paths=()
  local candidate_paths=(
    "${XDG_CONFIG_HOME}/nix/nix.conf"
    "${HOME}/.profile"
    "${HOME}/.bash_profile"
    "${HOME}/.bashrc"
    "${HOME}/.zshenv"
    "${zdotdir_path}/.zprofile"
    "${zdotdir_path}/.zshrc"
    "${HOME}/.gitconfig"
    "${XDG_CONFIG_HOME}/git/config"
    "${XDG_CONFIG_HOME}/python/pythonrc.py"
    "${cargo_home_path}/config.toml"
  )

  for candidate_path in "${candidate_paths[@]}"; do
    if is_nix_store_symlink "${candidate_path}"; then
      managed_paths+=("${candidate_path}")
    fi
  done

  if [ "${#managed_paths[@]}" -eq 0 ]; then
    return
  fi

  {
    echo "error: the following files are symlinks into the Nix store, so this machine already appears to be managed by an existing Home Manager configuration:"
    printf '  %s\n' "${managed_paths[@]}"
    echo "Running the script-based setup here would replace that configuration's Home Manager profile and detach these files from its control."
    echo "Keep managing this machine with your existing Home Manager configuration (e.g. your personal config repository) instead."
    echo "If you really want to switch to the script-based setup, remove the existing Home Manager configuration first and re-run this script."
  } >&2
  exit 1
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

  local original_mode=""
  original_mode="$(stat -L -c %a "${file_path}")"

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
  chmod "${original_mode}" "${file_path}"
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

# ===== Nix ===== #

nix_conf_include_block() {
  printf '%s\n' "!include ${shared_nix_config_path}"
}

ensure_nix_conf_include() {
  local nix_config_dir="${XDG_CONFIG_HOME}/nix"
  local nix_config_path="${nix_config_dir}/nix.conf"

  mkdir -p "${nix_config_dir}"

  if [ -f "${nix_config_path}" ] && grep -Fq "${shared_nix_config_path}" "${nix_config_path}"; then
    return
  fi

  prepend_block_once \
    "${nix_config_path}" \
    "# >>> ISSL nix config >>>" \
    "# <<< ISSL nix config <<<" \
    "$(nix_conf_include_block)"
}

# ===== Bash ===== #

profile_env_block() {
  printf '%s\n' \
    "if [ -f \"${shared_shell_env_path}\" ]; then" \
    "  . \"${shared_shell_env_path}\"" \
    "fi"
}

bash_profile_block() {
  # shellcheck disable=SC2016  # the block is emitted verbatim; $HOME, $-, and ${...} must stay literal.
  printf '%s\n' \
    'if [ -f "$HOME/.profile" ]; then' \
    '  . "$HOME/.profile"' \
    "fi" \
    'case $- in' \
    "*i*)" \
    '  if [ "${ISSL_BASHRC_LOADED:-0}" != "1" ] && [ -f "$HOME/.bashrc" ]; then' \
    '    . "$HOME/.bashrc"' \
    "  fi" \
    "  ;;" \
    "esac"
}

bashrc_block() {
  printf '%s\n' \
    "if [ -f \"${shared_bashrc_path}\" ]; then" \
    "  . \"${shared_bashrc_path}\"" \
    "fi"
}

ensure_bash_startup_files() {
  prepend_block_once \
    "${HOME}/.profile" \
    "# >>> ISSL shell env >>>" \
    "# <<< ISSL shell env <<<" \
    "$(profile_env_block)"
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

  # shellcheck disable=SC2016
  resolved_value="$(
    env -i \
      HOME="${HOME}" \
      XDG_CONFIG_HOME="${XDG_CONFIG_HOME}" \
      ZDOTDIR="" \
      PATH=/usr/bin:/bin \
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
  export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
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
    zdotdir_path="${XDG_CONFIG_HOME}/zsh"
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

resolve_zsh_bin() {
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

  if ! desired_zsh_path="$(resolve_zsh_bin)"; then
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

revert_login_shell_to_bash() {
  local bash_path="/bin/bash"

  if [ ! -x "${bash_path}" ] && ! bash_path="$(command -v bash)"; then
    echo "warning: could not locate a bash binary to revert the login shell. Set it manually with: chsh -s /bin/bash" >&2
    return 1
  fi

  if ! ensure_shell_listed_in_etc_shells "${bash_path}"; then
    return 1
  fi

  if ! chsh -s "${bash_path}"; then
    echo "warning: failed to run chsh. You can retry manually with: chsh -s ${bash_path}" >&2
    return 1
  fi

  echo "Reverted login shell to ${bash_path}. This will apply to new login sessions."
}

guard_login_shell_before_disabling_zsh() {
  local nix_zsh_path="${HOME}/.nix-profile/bin/zsh"
  local active_login_shell=""
  local response=""

  active_login_shell="$(current_login_shell || true)"
  if [ "${active_login_shell}" != "${nix_zsh_path}" ]; then
    return
  fi

  if [ -n "${issl_enable_zsh}" ] && is_no "${issl_enable_zsh}"; then
    # zsh was explicitly disabled; proceed straight to the bash fallback.
    :
  elif [ ! -t 0 ]; then
    echo "error: your login shell is the Nix-provided zsh (${nix_zsh_path}), but this non-interactive run would disable zsh and strand it." >&2
    echo "Re-run with ISSL_ENABLE_ZSH=yes to keep zsh, or ISSL_ENABLE_ZSH=no to disable it and revert the login shell to bash." >&2
    exit 1
  else
    echo "Your login shell is currently the Nix-provided zsh (${nix_zsh_path})."
    echo "Continuing without zsh will remove it and revert your login shell to bash."
    read -r -p "Continue and disable zsh? [y/N] " response
    if ! is_yes "${response}"; then
      echo "Aborted without changes. To keep zsh, re-run with it enabled:"
      echo "  ISSL_ENABLE_ZSH=yes bash ${repo_root}/scripts/apply.sh"
      echo "or answer yes when prompted to enable the shared zsh configuration."
      exit 1
    fi
  fi

  if ! revert_login_shell_to_bash; then
    echo "error: could not revert the login shell to bash; aborting before disabling zsh to avoid stranding your login shell." >&2
    echo "Fix the login shell manually (e.g. chsh -s /bin/bash) and re-run." >&2
    exit 1
  fi
}

# ===== Git ===== #

resolve_git_bin() {
  if [ -x "${HOME}/.nix-profile/bin/git" ]; then
    printf '%s\n' "${HOME}/.nix-profile/bin/git"
    return 0
  fi

  if command -v git >/dev/null 2>&1; then
    command -v git
    return 0
  fi

  return 1
}

ensure_git_include() {
  if ! "${git_bin}" config --global --get-all include.path | grep -Fxq "${shared_git_config_path}"; then
    "${git_bin}" config --global --add include.path "${shared_git_config_path}"
  fi
}

prompt_for_git_identity() {
  local git_name=""
  local git_email=""
  local missing_identity=0

  if ! git_name="$("${git_bin}" config --global --get user.name 2>/dev/null)" || [ -z "${git_name}" ]; then
    if [ -n "${git_user_name}" ]; then
      git_name="${git_user_name}"
    elif [ -t 0 ]; then
      read -r -p "Enter your full name for Git commits: " git_name
    else
      echo 'warning: Git user.name setup was skipped. Run with GIT_USER_NAME, or set it later with: git config --global user.name "Your Name"' >&2
      missing_identity=1
    fi
    if [ -n "${git_name}" ]; then
      "${git_bin}" config --global user.name "${git_name}"
    fi
  fi

  if ! git_email="$("${git_bin}" config --global --get user.email 2>/dev/null)" || [ -z "${git_email}" ]; then
    if [ -n "${git_user_email}" ]; then
      git_email="${git_user_email}"
    elif [ -t 0 ]; then
      read -r -p "Enter your email address for Git commits: " git_email
    else
      echo 'warning: Git user.email setup was skipped. Run with GIT_USER_EMAIL, or set it later with: git config --global user.email "you@example.com"' >&2
      missing_identity=1
    fi
    if [ -n "${git_email}" ]; then
      "${git_bin}" config --global user.email "${git_email}"
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
    "${XDG_CONFIG_HOME}/python/pythonrc.py" \
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

main() {
  if ! command -v nix >/dev/null 2>&1; then
    echo "nix is required before running scripts/apply.sh." >&2
    exit 1
  fi

  guard_against_existing_home_manager_files

  if [ -n "${NIX_CONFIG-}" ]; then
    export NIX_CONFIG="${NIX_CONFIG}"$'\n'"${nix_feature_config}"
  else
    export NIX_CONFIG="${nix_feature_config}"
  fi

  start_nix_daemon_without_systemd

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

  if [ "${zsh_enabled}" = "0" ]; then
    guard_login_shell_before_disabling_zsh
  fi

  nix --accept-flake-config --extra-experimental-features "nix-command flakes" run "${repo_root}#home-manager" -- \
    switch --flake "${repo_root}#${home_configuration_name}" --impure

  ensure_nix_conf_include
  ensure_bash_startup_files
  if [ "${zsh_enabled}" = "1" ]; then
    ensure_zsh_startup_files
    maybe_switch_login_shell_to_zsh
  fi
  if ! git_bin="$(resolve_git_bin)"; then
    echo "git was not found after the Home Manager switch; cannot wire the shared Git configuration." >&2
    exit 1
  fi
  ensure_git_include
  prompt_for_git_identity
  ensure_python_startup_file
  ensure_cargo_config_include

  echo "Applied the shared Home Manager configuration."
}

main "$@"
