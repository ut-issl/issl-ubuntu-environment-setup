#!/usr/bin/env bash
set -euo pipefail

home_dir="${HOME_DIR:?HOME_DIR is required}"
config_dir="${CONFIG_DIR:?CONFIG_DIR is required}"
nix_profile_bin="${home_dir}/.nix-profile/bin"

assert_cargo_installation() {
  test -x "${nix_profile_bin}/cargo"
  test "$(command -v cargo)" = "${nix_profile_bin}/cargo"
  cargo --version
}

assert_cargo_about_installation() {
  test -x "${nix_profile_bin}/cargo-about"
  test "$(command -v cargo-about)" = "${nix_profile_bin}/cargo-about"
  cargo-about --version
}

assert_rust_analyzer_installation() {
  test -x "${nix_profile_bin}/rust-analyzer"
  test "$(command -v rust-analyzer)" = "${nix_profile_bin}/rust-analyzer"
  rust-analyzer --version
}

assert_rustc_installation() {
  test -x "${nix_profile_bin}/rustc"
  test "$(command -v rustc)" = "${nix_profile_bin}/rustc"
  rustc --version
}

assert_rustup_installation() {
  test -x "${nix_profile_bin}/rustup"
  test "$(command -v rustup)" = "${nix_profile_bin}/rustup"
  rustup --version
}

assert_shared_rust_config_asset() {
  cmp --silent assets/rust/config.toml "${config_dir}/issl/rust/config.toml"
}

assert_cargo_config_include() {
  local cargo_config_path="${home_dir}/.cargo/config.toml"

  test -f "${cargo_config_path}"
  grep -Fq '# >>> ISSL cargo config >>>' "${cargo_config_path}"
  grep -Fq '# <<< ISSL cargo config <<<' "${cargo_config_path}"
  grep -Fq "${config_dir}/issl/rust/config.toml" "${cargo_config_path}"
}

main() {
  assert_cargo_installation
  assert_cargo_about_installation
  assert_rust_analyzer_installation
  assert_rustc_installation
  assert_rustup_installation
  assert_shared_rust_config_asset
  assert_cargo_config_include
}

main "$@"
