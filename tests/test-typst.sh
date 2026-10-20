#!/usr/bin/env bash
set -Eeuo pipefail

home_dir="${HOME_DIR:?HOME_DIR is required}"
common_dir="${COMMON_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
nix_profile_bin="${home_dir}/.nix-profile/bin"

# shellcheck source=tests/lib.sh
source "${common_dir}/tests/lib.sh"

test_typst_installation() {
  assert_nix_profile_command typst
  typst --version
}

test_typstyle_installation() {
  assert_nix_profile_command typstyle
  typstyle --version
}

main() {
  run_test test_typst_installation
  run_test test_typstyle_installation
}

main "$@"
