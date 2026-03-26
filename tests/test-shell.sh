#!/usr/bin/env bash
set -euo pipefail

home_dir="${HOME_DIR:?HOME_DIR is required}"
config_dir="${CONFIG_DIR:?CONFIG_DIR is required}"
nix_profile_bin="${home_dir}/.nix-profile/bin"
default_zdotdir="${home_dir}/.zsh"

assert_shared_shell_env() {
  cmp --silent assets/shell/env.sh "${config_dir}/issl/shell/env.sh"
  cmp --silent assets/shell/rc.sh "${config_dir}/issl/shell/rc.sh"
}

assert_shell_env_can_be_sourced() {
  env -i \
    HOME="${home_dir}" \
    SHELL_ENV_PATH="${config_dir}/issl/shell/env.sh" \
    XDG_CONFIG_HOME="${config_dir}" \
    PATH="/usr/bin:/bin" \
    bash <<'EOF'
. "${SHELL_ENV_PATH}"
test "${ISSL_CONFIG_HOME}" = "${XDG_CONFIG_HOME}/issl"
EOF
}

assert_bash_startup_files() {
  grep -Fq '# >>> ISSL bash profile >>>' "${home_dir}/.bash_profile"
  grep -Fq "${config_dir}/issl/bash/.bash_profile" "${home_dir}/.bash_profile"
  grep -Fq '# >>> ISSL bash rc >>>' "${home_dir}/.bashrc"
  grep -Fq "${config_dir}/issl/bash/.bashrc" "${home_dir}/.bashrc"
}

assert_zsh_installation() {
  test -x "${nix_profile_bin}/zsh"
}

assert_default_zsh_startup_files() {
  grep -Fq '# >>> ISSL zsh env >>>' "${home_dir}/.zshenv"
  # shellcheck disable=SC2016
  grep -Fq 'export ZDOTDIR="$HOME/.zsh"' "${home_dir}/.zshenv"
  grep -Fq '# >>> ISSL zsh profile >>>' "${default_zdotdir}/.zprofile"
  grep -Fq "${config_dir}/issl/zsh/.zprofile" "${default_zdotdir}/.zprofile"
  grep -Fq '# >>> ISSL zsh rc >>>' "${default_zdotdir}/.zshrc"
  grep -Fq "${config_dir}/issl/zsh/.zshrc" "${default_zdotdir}/.zshrc"
}

main() {
  assert_shared_shell_env
  assert_shell_env_can_be_sourced
  assert_bash_startup_files
  assert_zsh_installation
  assert_default_zsh_startup_files
}

main "$@"
