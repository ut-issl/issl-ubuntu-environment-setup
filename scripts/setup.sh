#!/usr/bin/env bash

set -euo pipefail

repo_url="${REPO_URL:-https://github.com/ut-issl/issl-ubuntu-environment-setup.git}"
repo_ref="${REPO_REF:-main}"
data_root="${XDG_DATA_HOME:-$HOME/.local/share}"
install_dir="${INSTALL_DIR:-$data_root/issl/ubuntu-environment-setup}"
ssh_dir="${HOME}/.ssh"
github_key_path="${ssh_dir}/github_ed25519"
ssh_config_path="${ssh_dir}/config"
temporary_git_installed=false

is_interactive() {
  [ -t 0 ] && [ -t 1 ]
}

prepend_path_if_exists() {
  local path_entry="$1"

  [ -d "${path_entry}" ] || return

  case ":${PATH}:" in
  *:"${path_entry}":*) ;;
  *) PATH="${path_entry}:${PATH}" ;;
  esac
}

refresh_path_for_nix() {
  prepend_path_if_exists "${HOME}/.nix-profile/bin"
  prepend_path_if_exists "/nix/var/nix/profiles/default/bin"

  if [ -n "${USER:-}" ]; then
    prepend_path_if_exists "/nix/var/nix/profiles/per-user/${USER}/profile/bin"
  fi

  hash -r 2>/dev/null || true
}

require_command() {
  local command_name="$1"

  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "required command not found: ${command_name}" >&2
    exit 1
  fi
}

prompt_yes_no() {
  local prompt_message="$1"
  local default_answer="${2:-no}"
  local reply

  if ! is_interactive; then
    return 1
  fi

  if ! read -r -p "${prompt_message} " reply; then
    return 1
  fi

  if [ -z "${reply}" ]; then
    case "${default_answer}" in
    y | Y | yes | YES | Yes)
      return 0
      ;;
    *)
      return 1
      ;;
    esac
  fi

  case "${reply}" in
  y | Y | yes | YES | Yes)
    return 0
    ;;
  *)
    return 1
    ;;
  esac
}

source_nix() {
  if command -v nix >/dev/null 2>&1; then
    return
  fi

  if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    # Official multi-user installs expose Nix through this profile script.
    # shellcheck source=/dev/null
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  elif [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    # Fallback for single-user installs.
    # shellcheck source=/dev/null
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  fi

  if ! command -v nix >/dev/null 2>&1; then
    echo "nix is installed but was not added to PATH in the current shell." >&2
    exit 1
  fi
}

ensure_nix() {
  if command -v nix >/dev/null 2>&1; then
    return
  fi

  require_command curl
  require_command sh

  sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
  source_nix
}

ensure_git() {
  if command -v git >/dev/null 2>&1; then
    return
  fi

  require_command sudo
  require_command apt-get

  sudo apt-get update
  sudo apt-get install -y git
  temporary_git_installed=true
}

ensure_ssh_directory() {
  mkdir -p "${ssh_dir}"
  chmod 700 "${ssh_dir}"
}

github_ssh_key_exists() {
  [ -f "${github_key_path}" ] && [ -f "${github_key_path}.pub" ]
}

can_access_repo() {
  git ls-remote --exit-code "${repo_url}" "${repo_ref}" >/dev/null 2>&1
}

is_github_ssh_repo_url() {
  case "${repo_url}" in
  git@github.com:* | ssh://git@github.com/*)
    return 0
    ;;
  *)
    return 1
    ;;
  esac
}

ensure_github_ssh_config() {
  ensure_ssh_directory

  if [ -f "${ssh_config_path}" ] &&
    grep -Eq '^[[:space:]]*Host[[:space:]]+github\.com([[:space:]]|$)' "${ssh_config_path}"; then
    return
  fi

  {
    echo "Host github.com"
    echo "  HostName github.com"
    echo "  User git"
    echo "  IdentityFile ~/.ssh/github_ed25519"
  } >>"${ssh_config_path}"
  chmod 600 "${ssh_config_path}"
}

create_github_ssh_key() {
  local key_comment=""

  ensure_ssh_directory
  require_command ssh-keygen

  read -r -p "Enter an email/comment for the GitHub SSH key (optional): " key_comment

  if [ -n "${key_comment}" ]; then
    ssh-keygen -t ed25519 -C "${key_comment}" -f "${github_key_path}"
  else
    ssh-keygen -t ed25519 -f "${github_key_path}"
  fi
}

prompt_github_ssh_registration() {
  echo "Register the following public key in GitHub:"
  echo "https://github.com/settings/keys"
  echo
  cat "${github_key_path}.pub"
  echo

  if ! prompt_yes_no "Type yes after the key has been registered in GitHub."; then
    echo "GitHub SSH key registration was not confirmed." >&2
    exit 1
  fi
}

prompt_github_ssh_setup() {
  if ! github_ssh_key_exists; then
    if ! prompt_yes_no "No GitHub SSH key was found at ${github_key_path}. Create one now? [y/N]"; then
      return
    fi

    create_github_ssh_key
  fi

  ensure_github_ssh_config
  prompt_github_ssh_registration
}

has_github_ssh_auth() {
  local ssh_output
  local ssh_status

  if ! command -v ssh >/dev/null 2>&1; then
    return 1
  fi

  ssh_output="$(ssh -T git@github.com 2>&1)" || ssh_status=$?
  ssh_status="${ssh_status:-0}"

  if [ "${ssh_status}" -eq 1 ] &&
    printf '%s\n' "${ssh_output}" | grep -Fq "successfully authenticated"; then
    return 0
  fi

  return 1
}

maybe_offer_github_ssh_setup() {
  if ! is_interactive; then
    return
  fi

  if has_github_ssh_auth; then
    return
  fi

  if ! prompt_yes_no "Set up GitHub SSH access now for future private repository use? [Y/n]" yes; then
    return
  fi

  prompt_github_ssh_setup
}

try_github_ssh_recovery() {
  if ! is_github_ssh_repo_url; then
    return 1
  fi

  if has_github_ssh_auth; then
    return 1
  fi

  prompt_github_ssh_setup

  if has_github_ssh_auth && can_access_repo; then
    return 0
  fi

  return 1
}

fail_repo_access() {
  cat >&2 <<EOF
failed to access ${repo_url}.
confirm that:
- if this is a GitHub SSH remote, your SSH key is registered with GitHub
- your account has access to the repository
- the repository ref exists: ${repo_ref}
EOF
  exit 1
}

ensure_repo_access() {
  if can_access_repo; then
    return
  fi

  if try_github_ssh_recovery; then
    return
  fi

  fail_repo_access
}

clone_repo() {
  if [ -e "${install_dir}" ]; then
    echo "install destination already exists: ${install_dir}" >&2
    exit 1
  fi

  git clone --branch "${repo_ref}" --single-branch "${repo_url}" "${install_dir}"
}

run_install() {
  bash "${install_dir}/scripts/apply.sh"
}

cleanup_temporary_git() {
  if [ "${temporary_git_installed}" != "true" ]; then
    return
  fi

  source_nix
  refresh_path_for_nix

  if ! command -v git >/dev/null 2>&1; then
    echo "git is not available after setup; keeping the apt-installed git." >&2
    return
  fi

  case "$(command -v git)" in
  /nix/store/* | "$HOME"/.nix-profile/* | /nix/var/nix/profiles/*)
    sudo apt-get remove -y git
    ;;
  *)
    echo "git is still resolved outside Nix; keeping the apt-installed git." >&2
    ;;
  esac
}

main() {
  ensure_nix
  ensure_git
  maybe_offer_github_ssh_setup
  ensure_repo_access
  clone_repo
  run_install
  cleanup_temporary_git

  echo "ISSL environment setup completed."
  echo "Repository clone: ${install_dir}"
}

main "$@"
