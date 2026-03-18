#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
profile_name="issl-common"
shared_git_config_path="${XDG_CONFIG_HOME:-$HOME/.config}/issl/git/.gitconfig"
nix_profile_path="${NIX_PROFILE_PATH:-}"
git_user_name="${GIT_USER_NAME:-}"
git_user_email="${GIT_USER_EMAIL:-}"
nix_feature_config="experimental-features = nix-command flakes"

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

if [ -n "${nix_profile_path}" ]; then
	nix profile add "${repo_root}#${profile_name}" \
		--accept-flake-config \
		--extra-experimental-features "nix-command flakes" \
		--profile "${nix_profile_path}"
else
	nix profile add "${repo_root}#${profile_name}" \
		--accept-flake-config \
		--extra-experimental-features "nix-command flakes"
fi

nix --accept-flake-config --extra-experimental-features "nix-command flakes" run "${repo_root}#home-manager" -- \
	switch --flake "${repo_root}#${home_configuration_name}" --impure

ensure_git_include
prompt_for_git_identity

echo "Installed the ISSL environment packages and applied shared Home Manager configuration."
echo "Installed package set: ${profile_name}"
echo "Shared git config: ${shared_git_config_path}"
if [ -n "${nix_profile_path}" ]; then
	echo "Nix profile path: ${nix_profile_path}"
fi
