#!/usr/bin/env bash
set -euo pipefail

home_dir="${HOME_DIR:?HOME_DIR is required}"
config_dir="${CONFIG_DIR:?CONFIG_DIR is required}"

assert_shared_shell_env() {
  cmp --silent assets/shell/env.sh "${config_dir}/issl/shell/env.sh"
  cmp --silent assets/shell/rc.sh "${config_dir}/issl/shell/rc.sh"
}

assert_shell_env_can_be_sourced() {
  # shellcheck disable=SC2016
  env -i \
    HOME="${home_dir}" \
    XDG_CONFIG_HOME="${config_dir}" \
    PATH="/usr/bin:/bin" \
    bash -c '
      shell_env_path="$1"
      . "${shell_env_path}"
      test "${ISSL_CONFIG_HOME}" = "${XDG_CONFIG_HOME}/issl"
      prepend_path /does/not/exist
    ' _ "${config_dir}/issl/shell/env.sh"
}

main() {
  assert_shared_shell_env
  assert_shell_env_can_be_sourced
}

main "$@"
