#!/usr/bin/env bash
set -euo pipefail

home_dir="${HOME_DIR:?HOME_DIR is required}"
config_dir="${CONFIG_DIR:?CONFIG_DIR is required}"
common_dir="${COMMON_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
nix_profile_bin="${home_dir}/.nix-profile/bin"
nix_profile_share="${home_dir}/.nix-profile/share"
default_zdotdir="${home_dir}/.zsh"
issl_enable_zsh="${ISSL_ENABLE_ZSH:?ISSL_ENABLE_ZSH is required}"

assert_shared_shell_assets() {
  cmp --silent "${common_dir}/assets/shell/env.sh" "${config_dir}/issl/shell/env.sh"
  cmp --silent "${common_dir}/assets/shell/rc.sh" "${config_dir}/issl/shell/rc.sh"
  cmp --silent "${common_dir}/assets/shell/.dircolors" "${config_dir}/issl/shell/.dircolors"
  cmp --silent "${common_dir}/assets/bash/bash_profile.bash" "${config_dir}/issl/bash/.bash_profile"
  cmp --silent "${common_dir}/assets/bash/bashrc.bash" "${config_dir}/issl/bash/.bashrc"
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
test "${ISSL_PYTHON_HOME}" = "${XDG_CONFIG_HOME}/issl/python"
test "${ISSL_RUST_HOME}" = "${XDG_CONFIG_HOME}/issl/rust"
test "${CARGO_HOME}" = "${HOME}/.cargo"
test "${PYTHONSTARTUP}" = "${HOME}/.python/.pythonrc.py"
test "${PYTHONHISTFILE}" = "${HOME}/.python/.python_history"
EOF
}

assert_bash_startup_files() {
  test -f "${home_dir}/.bash_profile"
  test -f "${home_dir}/.bashrc"

  grep -Fq "${config_dir}/issl/bash/.bash_profile" "${home_dir}/.bash_profile"
  grep -Fq "${config_dir}/issl/bash/.bashrc" "${home_dir}/.bashrc"
}

assert_shared_shell_tools() {
  test -f "${nix_profile_share}/bash-completion/bash_completion"

  test -x "${nix_profile_bin}/colordiff"
  test "$(command -v colordiff)" = "${nix_profile_bin}/colordiff"
  colordiff --version

  test -x "${nix_profile_bin}/dircolors"
  test "$(command -v dircolors)" = "${nix_profile_bin}/dircolors"
  dircolors --version
}

assert_zsh_enabled() {
  test -x "${nix_profile_bin}/zsh"
  test "$(command -v zsh)" = "${nix_profile_bin}/zsh"
  zsh --version
}

assert_shared_zsh_assets() {
  cmp --silent "${common_dir}/assets/zsh/zprofile.zsh" "${config_dir}/issl/zsh/.zprofile"
  cmp --silent "${common_dir}/assets/zsh/zshrc.zsh" "${config_dir}/issl/zsh/.zshrc"
}

assert_default_zsh_startup_files_enabled() {
  test -f "${home_dir}/.zshenv"
  test -f "${default_zdotdir}/.zprofile"
  test -f "${default_zdotdir}/.zshrc"

  grep -Fq "${config_dir}/issl/zsh/.zprofile" "${default_zdotdir}/.zprofile"
  grep -Fq "${config_dir}/issl/zsh/.zshrc" "${default_zdotdir}/.zshrc"
}

assert_zsh_disabled() {
  test ! -x "${nix_profile_bin}/zsh"
  test ! -e "${home_dir}/.zshenv"
  test ! -e "${default_zdotdir}/.zprofile"
  test ! -e "${default_zdotdir}/.zshrc"
}

main() {
  assert_shared_shell_assets
  assert_shell_env_can_be_sourced
  assert_bash_startup_files
  assert_shared_shell_tools

  if [ "${issl_enable_zsh}" = "1" ]; then
    assert_zsh_enabled
    assert_shared_zsh_assets
    assert_default_zsh_startup_files_enabled
  else
    assert_zsh_disabled
  fi
}

main "$@"
