#!/usr/bin/env bash
set -euo pipefail

profile_path="${PROFILE_PATH:?PROFILE_PATH is required}"
home_dir="${HOME_DIR:?HOME_DIR is required}"
config_dir="${CONFIG_DIR:?CONFIG_DIR is required}"

assert_git_installation() {
  test -x "${profile_path}/bin/git"
  PATH="${profile_path}/bin:${PATH}" git --version
}

assert_shared_git_config() {
  cmp --silent assets/git/.gitconfig "${config_dir}/issl/git/.gitconfig"
}

assert_global_git_include() {
  local include_path
  include_path="$(
    HOME="${home_dir}" XDG_CONFIG_HOME="${config_dir}" \
      git config --global --get-all include.path
  )"
  test "${include_path}" = "${config_dir}/issl/git/.gitconfig"
}

assert_git_identity() {
  local user_name
  local user_email

  user_name="$(
    HOME="${home_dir}" XDG_CONFIG_HOME="${config_dir}" \
      git config --global --get user.name
  )"
  test "${user_name}" = "ISSL Test User"

  user_email="$(
    HOME="${home_dir}" XDG_CONFIG_HOME="${config_dir}" \
      git config --global --get user.email
  )"
  test "${user_email}" = "issl-test@example.com"
}

main() {
  assert_git_installation
  assert_shared_git_config
  assert_global_git_include
  assert_git_identity
}

main "$@"
