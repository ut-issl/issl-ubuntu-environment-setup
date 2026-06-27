#!/usr/bin/env bash
set -Eeuo pipefail

home_dir="${HOME_DIR:?HOME_DIR is required}"
config_dir="${CONFIG_DIR:?CONFIG_DIR is required}"
common_dir="${COMMON_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
nix_profile_bin="${home_dir}/.nix-profile/bin"
export RUSTUP_HOME="${home_dir}/.rustup"

# shellcheck source=tests/lib.sh
source "${common_dir}/tests/lib.sh"

assert_cargo_about_installation() {
  test -x "${nix_profile_bin}/cargo-about"
  test "$(command -v cargo-about)" = "${nix_profile_bin}/cargo-about"
  cargo-about --version
}

assert_rustup_installation() {
  test -x "${nix_profile_bin}/rustup"
  test "$(command -v rustup)" = "${nix_profile_bin}/rustup"
  rustup --version
}

assert_cargo_installation() {
  command -v cargo >/dev/null 2>&1
  cargo --version
}

assert_rustc_installation() {
  command -v rustc >/dev/null 2>&1
  rustc --version
}

assert_default_toolchain_stable() {
  rustup show active-toolchain | grep -Eq '^stable(-|$)'
}

assert_shared_rust_config_asset() {
  cmp "${common_dir}/assets/rust/config.toml" "${config_dir}/issl/rust/config.toml"
}

assert_cargo_config_include() {
  local cargo_config_path="${home_dir}/.cargo/config.toml"

  test -f "${cargo_config_path}"
  grep -Fq "${config_dir}/issl/rust/config.toml" "${cargo_config_path}"
}

main() {
  run_assert assert_cargo_about_installation
  run_assert assert_rustup_installation
  run_assert assert_cargo_installation
  run_assert assert_rustc_installation
  run_assert assert_default_toolchain_stable
  run_assert assert_shared_rust_config_asset
  run_assert assert_cargo_config_include
}

main "$@"
