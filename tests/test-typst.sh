#!/usr/bin/env bash
set -Eeuo pipefail

home_dir="${HOME_DIR:?HOME_DIR is required}"
common_dir="${COMMON_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
nix_profile_bin="${home_dir}/.nix-profile/bin"

# shellcheck source=tests/lib.sh
source "${common_dir}/tests/lib.sh"

assert_typst_installation() {
  [[ -x "${nix_profile_bin}/typst" ]]
  [[ "$(command -v typst)" == "${nix_profile_bin}/typst" ]]
  typst --version
}

assert_typstyle_installation() {
  [[ -x "${nix_profile_bin}/typstyle" ]]
  [[ "$(command -v typstyle)" == "${nix_profile_bin}/typstyle" ]]
  typstyle --version
}

main() {
  run_assert assert_typst_installation
  run_assert assert_typstyle_installation
}

main "$@"
