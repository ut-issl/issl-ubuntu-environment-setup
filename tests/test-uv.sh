#!/usr/bin/env bash
set -euo pipefail

home_dir="${HOME_DIR:?HOME_DIR is required}"
nix_profile_bin="${home_dir}/.nix-profile/bin"

assert_uv_installation() {
  test -x "${nix_profile_bin}/uv"
  test "$(command -v uv)" = "${nix_profile_bin}/uv"
  uv --version
}

main() {
  assert_uv_installation
}

main "$@"
