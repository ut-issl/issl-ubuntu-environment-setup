#!/usr/bin/env bash
set -euo pipefail

home_dir="${HOME_DIR:?HOME_DIR is required}"
nix_profile_bin="${home_dir}/.nix-profile/bin"

assert_cargo_installation() {
  test -x "${nix_profile_bin}/cargo"
  test "$(command -v cargo)" = "${nix_profile_bin}/cargo"
  cargo --version
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

main() {
  assert_cargo_installation
  assert_rustc_installation
  assert_rustup_installation
}

main "$@"
