#!/usr/bin/env bash

set -euo pipefail

repo_url="${REPO_URL:-git@github.com:ut-issl/issl-ubuntu-environment-setup.git}"
repo_ref="${REPO_REF:-main}"
data_root="${XDG_DATA_HOME:-$HOME/.local/share}"
install_dir="${INSTALL_DIR:-$data_root/issl/ubuntu-environment-setup}"
ssh_dir="${HOME}/.ssh"
github_key_path="${ssh_dir}/github_ed25519"
ssh_config_path="${ssh_dir}/config"
temporary_git_installed=false

require_command() {
  local command_name="$1"

  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "required command not found: ${command_name}" >&2
    exit 1
  fi
}

prompt_yes_no() {
  local prompt_message="$1"
  local reply

  read -r -p "${prompt_message} " reply
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

github_host_is_configured() {
  [ -f "${ssh_config_path}" ] &&
    grep -Eq '^[[:space:]]*Host[[:space:]]+github\.com([[:space:]]|$)' "${ssh_config_path}"
}

append_github_ssh_config() {
  ensure_ssh_directory

  if github_host_is_configured; then
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

maybe_setup_github_ssh() {
  if ! github_ssh_key_exists; then
    if ! prompt_yes_no "No GitHub SSH key was found at ${github_key_path}. Create one now? [y/N]"; then
      return
    fi

    create_github_ssh_key
  fi

  append_github_ssh_config
  prompt_github_ssh_registration
}

ensure_repo_access() {
  if git ls-remote --exit-code "${repo_url}" "${repo_ref}" >/dev/null 2>&1; then
    return
  fi

  maybe_setup_github_ssh

  if git ls-remote --exit-code "${repo_url}" "${repo_ref}" >/dev/null 2>&1; then
    return
  fi

  cat >&2 <<EOF
failed to access ${repo_url}.
confirm that:
- your SSH key is registered with GitHub
- your account has access to the private repository
- the repository ref exists: ${repo_ref}
EOF
  exit 1
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
  ensure_repo_access
  clone_repo
  run_install
  cleanup_temporary_git

  echo "ISSL environment setup completed."
  echo "Repository clone: ${install_dir}"
}

main "$@"
