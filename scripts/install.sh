#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config_root="${XDG_CONFIG_HOME:-$HOME/.config}/issl"
shared_git_config_dir="${config_root}/git"
shared_git_config_path="${shared_git_config_dir}/.gitconfig"
profile_name="issl-common"

if ! command -v nix >/dev/null 2>&1; then
	echo "nix is required before running scripts/install.sh." >&2
	exit 1
fi

mkdir -p "${shared_git_config_dir}"
install -m 0644 "${repo_root}/assets/git/.gitconfig" "${shared_git_config_path}"

nix profile install "${repo_root}#${profile_name}" \
	--extra-experimental-features "nix-command flakes"

if ! git config --global --get-all include.path | grep -Fxq "${shared_git_config_path}"; then
	git config --global --add include.path "${shared_git_config_path}"
fi

echo "Installed the ISSL environment packages and shared Git configuration."
echo "Installed package set: ${profile_name}"
echo "Shared git config: ${shared_git_config_path}"
