#!/usr/bin/env bash

set -euo pipefail

default_repo_ref="v0.3.1"
repo_url="${REPO_URL:-https://github.com/ut-issl/issl-ubuntu-environment-setup.git}"
repo_ref="${REPO_REF:-${default_repo_ref}}"
data_root="${XDG_DATA_HOME:-$HOME/.local/share}"
install_dir="${INSTALL_DIR:-$data_root/issl/ubuntu-environment-setup}"

default_bootstrap_url() {
  case "${repo_ref}" in
  v*)
    printf 'https://github.com/ut-issl/issl-ubuntu-environment-setup/releases/download/%s/bootstrap-host.sh\n' "${repo_ref}"
    ;;
  *)
    printf 'https://raw.githubusercontent.com/ut-issl/issl-ubuntu-environment-setup/%s/scripts/bootstrap-host.sh\n' "${repo_ref}"
    ;;
  esac
}

load_bootstrap_host() {
  local bootstrap_url="${BOOTSTRAP_URL:-$(default_bootstrap_url)}"
  local script_dir=""
  local temporary_bootstrap=""

  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

  if [ -f "${script_dir}/bootstrap-host.sh" ]; then
    # shellcheck source=scripts/bootstrap-host.sh
    . "${script_dir}/bootstrap-host.sh"
    return
  fi

  if ! command -v curl >/dev/null 2>&1; then
    echo "required command not found: curl" >&2
    exit 1
  fi

  temporary_bootstrap="$(mktemp)"
  curl -fsSL "${bootstrap_url}" -o "${temporary_bootstrap}"
  # shellcheck source=/dev/null
  . "${temporary_bootstrap}"
}

nix_git() {
  nix --extra-experimental-features "nix-command flakes" shell nixpkgs#git --command git "$@"
}

can_access_repo() {
  nix_git ls-remote --exit-code "${repo_url}" "${repo_ref}" >/dev/null 2>&1
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

try_github_ssh_recovery() {
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

  if is_github_ssh_repo_url && try_github_ssh_recovery; then
    return
  fi

  fail_repo_access
}

clone_repo() {
  if [ -e "${install_dir}" ]; then
    echo "install destination already exists: ${install_dir}" >&2
    exit 1
  fi

  nix_git clone --branch "${repo_ref}" --single-branch "${repo_url}" "${install_dir}"
}

run_install() {
  bash "${install_dir}/scripts/apply.sh"
}

main() {
  load_bootstrap_host
  bootstrap_host
  ensure_repo_access
  clone_repo
  run_install

  echo "ISSL environment setup completed."
  echo "Repository clone: ${install_dir}"
}

main "$@"
