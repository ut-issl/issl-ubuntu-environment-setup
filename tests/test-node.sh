#!/usr/bin/env bash
set -Eeuo pipefail

home_dir="${HOME_DIR:?HOME_DIR is required}"
common_dir="${COMMON_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
nix_profile_bin="${home_dir}/.nix-profile/bin"

# shellcheck source=tests/lib.sh
source "${common_dir}/tests/lib.sh"

assert_node_installation() {
  test -x "${nix_profile_bin}/node"
  test "$(command -v node)" = "${nix_profile_bin}/node"
  node --version
}

assert_npm_installation() {
  test -x "${nix_profile_bin}/npm"
  test "$(command -v npm)" = "${nix_profile_bin}/npm"
  npm --version
}

assert_npx_installation() {
  test -x "${nix_profile_bin}/npx"
  test "$(command -v npx)" = "${nix_profile_bin}/npx"
  npx --version
}

main() {
  run_assert assert_node_installation
  run_assert assert_npm_installation
  run_assert assert_npx_installation
}

main "$@"
