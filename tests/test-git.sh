#!/usr/bin/env bash
set -Eeuo pipefail

home_dir="${HOME_DIR:?HOME_DIR is required}"
config_dir="${CONFIG_DIR:?CONFIG_DIR is required}"
common_dir="${COMMON_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
nix_profile_bin="${home_dir}/.nix-profile/bin"

# shellcheck source=tests/lib.sh
source "${common_dir}/tests/lib.sh"

test_git_installation() {
  [[ -x "${nix_profile_bin}/git" ]]
  [[ "$(command -v git)" == "${nix_profile_bin}/git" ]]
  git --version
}

test_gh_installation() {
  [[ -x "${nix_profile_bin}/gh" ]]
  [[ "$(command -v gh)" == "${nix_profile_bin}/gh" ]]
  gh --version
}

test_act_installation() {
  [[ -x "${nix_profile_bin}/act" ]]
  [[ "$(command -v act)" == "${nix_profile_bin}/act" ]]
  act --version
}

test_actionlint_installation() {
  [[ -x "${nix_profile_bin}/actionlint" ]]
  [[ "$(command -v actionlint)" == "${nix_profile_bin}/actionlint" ]]
  actionlint --version
}

test_zizmor_installation() {
  [[ -x "${nix_profile_bin}/zizmor" ]]
  [[ "$(command -v zizmor)" == "${nix_profile_bin}/zizmor" ]]
  zizmor --version
}

test_shared_git_config() {
  cmp "${common_dir}/home-modules/git/gitconfig" "${config_dir}/issl/git/.gitconfig"
}

test_global_git_include() {
  HOME="${home_dir}" XDG_CONFIG_HOME="${config_dir}" \
    git config --global --get-all include.path |
    grep -Fx "${config_dir}/issl/git/.gitconfig"
}

test_git_identity() {
  local user_name
  local user_email

  if [[ -n ${EXPECTED_GIT_USER_NAME:-} ]]; then
    user_name="$(
      HOME="${home_dir}" XDG_CONFIG_HOME="${config_dir}" \
        git config --global --get user.name
    )"
    [[ ${user_name} == "${EXPECTED_GIT_USER_NAME}" ]]
  fi

  if [[ -n ${EXPECTED_GIT_USER_EMAIL:-} ]]; then
    user_email="$(
      HOME="${home_dir}" XDG_CONFIG_HOME="${config_dir}" \
        git config --global --get user.email
    )"
    [[ ${user_email} == "${EXPECTED_GIT_USER_EMAIL}" ]]
  fi
}

main() {
  run_test test_git_installation
  run_test test_gh_installation
  run_test test_act_installation
  run_test test_actionlint_installation
  run_test test_zizmor_installation
  run_test test_shared_git_config
  run_test test_global_git_include
  run_test test_git_identity
}

main "$@"
