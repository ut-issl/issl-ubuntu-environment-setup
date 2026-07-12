#!/usr/bin/env bash

set -euo pipefail

ssh_dir="${HOME}/.ssh"
github_key_path="${ssh_dir}/github_ed25519"
ssh_config_path="${ssh_dir}/config"

require_command() {
  local command_name="$1"

  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "required command not found: ${command_name}" >&2
    exit 1
  fi
}

is_interactive() {
  [ -t 0 ] && [ -t 1 ]
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
    is_yes "${default_answer}"
    return
  fi

  is_yes "${reply}"
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

  if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ] ||
    [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    source_nix
    return
  fi

  require_command curl
  require_command sh

  sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
  source_nix
}

is_systemd_available() {
  [ -d /run/systemd/system ] && command -v systemctl >/dev/null 2>&1
}

resolve_nix_daemon_path() {
  if command -v nix-daemon >/dev/null 2>&1; then
    command -v nix-daemon
    return 0
  fi

  if [ -x /nix/var/nix/profiles/default/bin/nix-daemon ]; then
    printf '%s\n' "/nix/var/nix/profiles/default/bin/nix-daemon"
    return 0
  fi

  return 1
}

start_nix_daemon_without_systemd() {
  local nix_daemon_path=""

  if is_systemd_available; then
    return
  fi

  if pgrep -x nix-daemon >/dev/null 2>&1; then
    return
  fi

  if ! nix_daemon_path="$(resolve_nix_daemon_path)"; then
    echo "warning: nix-daemon binary was not found. Nix commands may fail in no-systemd environments." >&2
    return
  fi

  if [ "$(id -u)" = "0" ]; then
    setsid "${nix_daemon_path}" --daemon >/dev/null 2>&1 &
  elif command -v sudo >/dev/null 2>&1; then
    if [ -t 0 ]; then
      if ! sudo -v; then
        echo "warning: failed to authenticate via sudo. Nix commands may fail." >&2
        return
      fi
    elif ! sudo -n true >/dev/null 2>&1; then
      echo "warning: cannot start nix-daemon automatically (sudo requires a password in non-interactive mode)." >&2
      return
    fi
    sudo -n setsid "${nix_daemon_path}" --daemon >/dev/null 2>&1 &
  else
    echo "warning: cannot start nix-daemon automatically (sudo is unavailable in a no-systemd environment)." >&2
    return
  fi

  for _ in {1..10}; do
    if nix --extra-experimental-features "nix-command flakes" store info >/dev/null 2>&1; then
      return
    fi
    sleep 1
  done

  echo "warning: attempted to start nix-daemon, but it is not responding yet. Nix commands may fail." >&2
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

ensure_ssh_directory() {
  mkdir -p "${ssh_dir}"
  chmod 700 "${ssh_dir}"
}

github_ssh_key_exists() {
  [ -f "${github_key_path}" ] && [ -f "${github_key_path}.pub" ]
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

ensure_github_ssh_config() {
  ensure_ssh_directory

  if [ -f "${ssh_config_path}" ] &&
    grep -Eq '^[[:space:]]*[Hh][Oo][Ss][Tt][[:space:]]+github\.com([[:space:]]|$)' "${ssh_config_path}"; then
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

should_install_docker() {
  if is_yes "${ISSL_INSTALL_DOCKER-}"; then
    return 0
  fi

  if is_no "${ISSL_INSTALL_DOCKER-}"; then
    return 1
  fi

  if ! is_interactive; then
    return 1
  fi

  prompt_yes_no "Install Docker Engine for local container execution? [Y/n]" yes
}

should_add_user_to_docker_group() {
  if is_no "${ISSL_ADD_USER_TO_DOCKER_GROUP-}"; then
    return 1
  fi

  if is_yes "${ISSL_ADD_USER_TO_DOCKER_GROUP-}"; then
    return 0
  fi

  return 0
}

target_docker_user() {
  if [ -n "${SUDO_USER-}" ] && [ "${SUDO_USER}" != "root" ]; then
    printf '%s\n' "${SUDO_USER}"
  elif [ -n "${USER-}" ]; then
    printf '%s\n' "${USER}"
  else
    id -un
  fi
}

install_docker_engine() {
  local apt_keyrings_dir="/etc/apt/keyrings"
  local docker_user=""
  local ubuntu_codename=""

  require_command sudo
  require_command apt-get
  require_command dpkg

  if [ -r /etc/os-release ]; then
    # shellcheck source=/dev/null
    . /etc/os-release
  fi

  ubuntu_codename="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
  if [ -z "${ubuntu_codename}" ]; then
    echo "could not determine the Ubuntu codename for Docker repository setup." >&2
    exit 1
  fi

  sudo apt-get update
  sudo apt-get install -y ca-certificates curl gnupg
  require_command curl
  require_command gpg
  sudo install -m 0755 -d "${apt_keyrings_dir}"

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg |
    gpg --dearmor |
    sudo tee "${apt_keyrings_dir}/docker.gpg" >/dev/null
  sudo chmod a+r "${apt_keyrings_dir}/docker.gpg"

  printf 'deb [arch=%s signed-by=%s/docker.gpg] https://download.docker.com/linux/ubuntu %s stable\n' \
    "$(dpkg --print-architecture)" "${apt_keyrings_dir}" "${ubuntu_codename}" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  if should_add_user_to_docker_group; then
    docker_user="$(target_docker_user)"
    sudo usermod -aG docker "${docker_user}"
    echo "Added ${docker_user} to the docker group."
    echo "Log out and back in, or run 'newgrp docker', before using Docker without sudo."
  fi

  if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
    sudo systemctl enable --now docker.service
  fi
}

maybe_install_docker_engine() {
  if ! should_install_docker; then
    return
  fi

  install_docker_engine
}

bootstrap_host() {
  ensure_nix
  start_nix_daemon_without_systemd
  maybe_offer_github_ssh_setup
  maybe_install_docker_engine
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  bootstrap_host
fi
