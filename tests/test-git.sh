#!/usr/bin/env bash
set -Eeuo pipefail

home_dir="${HOME_DIR:?HOME_DIR is required}"
config_dir="${CONFIG_DIR:?CONFIG_DIR is required}"
common_dir="${COMMON_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
nix_profile_bin="${home_dir}/.nix-profile/bin"

# shellcheck source=tests/lib.sh
source "${common_dir}/tests/lib.sh"

assert_git_installation() {
  test -x "${nix_profile_bin}/git"
  test "$(command -v git)" = "${nix_profile_bin}/git"
  git --version
}

assert_gh_installation() {
  test -x "${nix_profile_bin}/gh"
  test "$(command -v gh)" = "${nix_profile_bin}/gh"
  gh --version
}

assert_shared_git_config() {
  cmp "${common_dir}/assets/git/.gitconfig" "${config_dir}/issl/git/.gitconfig"
}

assert_global_git_include() {
  HOME="${home_dir}" XDG_CONFIG_HOME="${config_dir}" \
    git config --global --get-all include.path |
    grep -Fx "${config_dir}/issl/git/.gitconfig"
}

assert_git_identity() {
  local user_name
  local user_email

  if [ -n "${EXPECTED_GIT_USER_NAME:-}" ]; then
    user_name="$(
      HOME="${home_dir}" XDG_CONFIG_HOME="${config_dir}" \
        git config --global --get user.name
    )"
    test "${user_name}" = "${EXPECTED_GIT_USER_NAME}"
  fi

  if [ -n "${EXPECTED_GIT_USER_EMAIL:-}" ]; then
    user_email="$(
      HOME="${home_dir}" XDG_CONFIG_HOME="${config_dir}" \
        git config --global --get user.email
    )"
    test "${user_email}" = "${EXPECTED_GIT_USER_EMAIL}"
  fi
}

main() {
  run_assert assert_git_installation
  run_assert assert_gh_installation
  run_assert assert_shared_git_config
  run_assert assert_global_git_include
  run_assert assert_git_identity
}

main "$@"
