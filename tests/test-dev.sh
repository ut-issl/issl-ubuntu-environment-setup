#!/usr/bin/env bash
set -Eeuo pipefail

home_dir="${HOME_DIR:?HOME_DIR is required}"
common_dir="${COMMON_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
nix_profile_bin="${home_dir}/.nix-profile/bin"

# shellcheck source=tests/lib.sh
source "${common_dir}/tests/lib.sh"

assert_commitizen_installation() {
  test -x "${nix_profile_bin}/cz"
  test "$(command -v cz)" = "${nix_profile_bin}/cz"
  cz version
}

assert_prek_installation() {
  test -x "${nix_profile_bin}/prek"
  test "$(command -v prek)" = "${nix_profile_bin}/prek"
  prek --version
}

assert_typos_installation() {
  test -x "${nix_profile_bin}/typos"
  test "$(command -v typos)" = "${nix_profile_bin}/typos"
  typos --version
}

main() {
  run_assert assert_commitizen_installation
  run_assert assert_prek_installation
  run_assert assert_typos_installation
}

main "$@"
