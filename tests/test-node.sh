#!/usr/bin/env bash
set -Eeuo pipefail

home_dir="${HOME_DIR:?HOME_DIR is required}"
common_dir="${COMMON_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
nix_profile_bin="${home_dir}/.nix-profile/bin"

# shellcheck source=tests/lib.sh
source "${common_dir}/tests/lib.sh"

test_node_installation() {
  [[ -x "${nix_profile_bin}/node" ]]
  [[ "$(command -v node)" == "${nix_profile_bin}/node" ]]
  node --version
}

test_npm_installation() {
  [[ -x "${nix_profile_bin}/npm" ]]
  [[ "$(command -v npm)" == "${nix_profile_bin}/npm" ]]
  npm --version
}

test_npx_installation() {
  [[ -x "${nix_profile_bin}/npx" ]]
  [[ "$(command -v npx)" == "${nix_profile_bin}/npx" ]]
  npx --version
}

main() {
  run_test test_node_installation
  run_test test_npm_installation
  run_test test_npx_installation
}

main "$@"
