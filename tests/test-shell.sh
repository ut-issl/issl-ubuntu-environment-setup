#!/usr/bin/env bash
set -Eeuo pipefail

home_dir="${HOME_DIR:?HOME_DIR is required}"
config_dir="${CONFIG_DIR:?CONFIG_DIR is required}"
common_dir="${COMMON_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
nix_profile_bin="${home_dir}/.nix-profile/bin"
nix_profile_share="${home_dir}/.nix-profile/share"
default_zdotdir="${config_dir}/zsh"
issl_enable_zsh="${ISSL_ENABLE_ZSH:?ISSL_ENABLE_ZSH is required}"

# shellcheck source=tests/lib.sh
source "${common_dir}/tests/lib.sh"

assert_shared_shell_assets() {
  cmp "${common_dir}/assets/shell/env.sh" "${config_dir}/issl/shell/env.sh"
  cmp "${common_dir}/assets/shell/rc.sh" "${config_dir}/issl/shell/rc.sh"
  cmp "${common_dir}/assets/shell/.dircolors" "${config_dir}/issl/shell/.dircolors"
  cmp "${common_dir}/assets/bash/bashrc.bash" "${config_dir}/issl/bash/.bashrc"
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
test "${PYTHONSTARTUP}" = "${XDG_CONFIG_HOME}/python/pythonrc.py"
test "${PYTHON_HISTORY}" = "${XDG_STATE_HOME:-$HOME/.local/state}/python/python_history"
EOF
}

assert_bash_startup_files() {
  test -f "${home_dir}/.profile"
  test -f "${home_dir}/.bash_profile"
  test -f "${home_dir}/.bashrc"
}

assert_profile_not_shadowed_by_bash_profile() {
  # Regression guard: ~/.bash_profile must source ~/.profile so it does not hide it.
  # shellcheck disable=SC2016  # $HOME is matched literally in the file content, not expanded.
  grep -Eq '(^|[[:space:]])(\.|source)[[:space:]]+"?(\$HOME|~)/\.profile"?' "${home_dir}/.bash_profile"
}

assert_bash_startup_is_loaded() {
  # Drive a login + interactive bash and confirm the shared startup files ran (observed through their load guards)
  # and that env.sh put the Nix profile bin on PATH by itself, without the Nix installer's system-wide shell hooks.
  # shellcheck disable=SC2016  # ${...} inside the single-quoted -c argument expand in the subshell.
  env -i \
    HOME="${home_dir}" \
    XDG_CONFIG_HOME="${config_dir}" \
    PATH="/usr/bin:/bin" \
    TERM=dumb \
    bash -lic '
      ok=1
      [ "${ISSL_ENV_SH_LOADED:-0}" = "1" ] || { echo "login shell did not load the shared env.sh" >&2; ok=0; }
      [ "${ISSL_BASHRC_LOADED:-0}" = "1" ] || { echo "interactive shell did not load the shared bashrc" >&2; ok=0; }
      [ "$(command -v colordiff)" = "${HOME}/.nix-profile/bin/colordiff" ] || { echo "env.sh did not add the Nix profile bin to PATH" >&2; ok=0; }
      [ "${ok}" = "1" ]
    '
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
  cmp "${common_dir}/assets/zsh/zprofile.zsh" "${config_dir}/issl/zsh/.zprofile"
  cmp "${common_dir}/assets/zsh/zshrc.zsh" "${config_dir}/issl/zsh/.zshrc"
}

assert_zsh_startup_files() {
  test -f "${home_dir}/.zshenv"
  test -f "${default_zdotdir}/.zprofile"
  test -f "${default_zdotdir}/.zshrc"
}

assert_zsh_startup_is_loaded() {
  # shellcheck disable=SC2016  # ${...} inside the single-quoted -c argument expand in the subshell.
  env -i \
    HOME="${home_dir}" \
    XDG_CONFIG_HOME="${config_dir}" \
    PATH="/usr/bin:/bin" \
    TERM=dumb \
    "${nix_profile_bin}/zsh" -lic '
      ok=1
      [ "${ISSL_ENV_SH_LOADED:-0}" = "1" ] || { echo "login shell did not load the shared env.sh" >&2; ok=0; }
      [ "${ISSL_ZSHRC_LOADED:-0}" = "1" ] || { echo "interactive shell did not load the shared zshrc" >&2; ok=0; }
      [ "$(command -v colordiff)" = "${HOME}/.nix-profile/bin/colordiff" ] || { echo "env.sh did not add the Nix profile bin to PATH" >&2; ok=0; }
      [ "${ok}" = "1" ]
    '
}

assert_zsh_disabled() {
  test ! -x "${nix_profile_bin}/zsh"
  test ! -e "${home_dir}/.zshenv"
  test ! -e "${default_zdotdir}/.zprofile"
  test ! -e "${default_zdotdir}/.zshrc"
}

main() {
  run_assert assert_shared_shell_assets
  run_assert assert_shell_env_can_be_sourced
  run_assert assert_bash_startup_files
  run_assert assert_bash_startup_is_loaded
  run_assert assert_profile_not_shadowed_by_bash_profile
  run_assert assert_shared_shell_tools

  if [ "${issl_enable_zsh}" = "1" ]; then
    run_assert assert_zsh_enabled
    run_assert assert_shared_zsh_assets
    run_assert assert_zsh_startup_files
    run_assert assert_zsh_startup_is_loaded
  else
    run_assert assert_zsh_disabled
  fi
}

main "$@"
