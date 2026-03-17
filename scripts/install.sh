#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
profile_name="issl-common"
shared_git_config_path="${XDG_CONFIG_HOME:-$HOME/.config}/issl/git/.gitconfig"

ensure_git_include() {
	if ! git config --global --get-all include.path | grep -Fxq "${shared_git_config_path}"; then
		git config --global --add include.path "${shared_git_config_path}"
	fi
}

prompt_for_git_identity() {
	local git_name=""
	local git_email=""

	if ! git_name="$(git config --global --get user.name 2>/dev/null)" || [ -z "${git_name}" ]; then
		read -r -p "Enter your full name for Git commits: " git_name
		if [ -n "${git_name}" ]; then
			git config --global user.name "${git_name}"
		fi
	fi

	if ! git_email="$(git config --global --get user.email 2>/dev/null)" || [ -z "${git_email}" ]; then
		read -r -p "Enter your email address for Git commits: " git_email
		if [ -n "${git_email}" ]; then
			git config --global user.email "${git_email}"
		fi
	fi
}

if ! command -v nix >/dev/null 2>&1; then
	echo "nix is required before running scripts/install.sh." >&2
	exit 1
fi

current_system="$(
	nix --extra-experimental-features "nix-command flakes" \
		eval --impure --raw --expr builtins.currentSystem
)"
home_configuration_name="issl-common-${current_system}"

nix profile install "${repo_root}#${profile_name}" \
	--extra-experimental-features "nix-command flakes"

nix --extra-experimental-features "nix-command flakes" run "${repo_root}#home-manager" -- \
	switch --flake "${repo_root}#${home_configuration_name}" --impure

ensure_git_include
prompt_for_git_identity

echo "Installed the ISSL environment packages and applied shared Home Manager configuration."
echo "Installed package set: ${profile_name}"
echo "Shared git config: ${shared_git_config_path}"
