#!/usr/bin/env bash
set -Eeuo pipefail

home_dir="${HOME_DIR:?HOME_DIR is required}"
common_dir="${COMMON_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
nix_profile_bin="${home_dir}/.nix-profile/bin"

# shellcheck source=tests/lib.sh
source "${common_dir}/tests/lib.sh"

test_commitizen_installation() {
  assert_command_path "${nix_profile_bin}/cz"
  cz version
}

test_prek_installation() {
  assert_command_path "${nix_profile_bin}/prek"
  prek --version
}

test_typos_installation() {
  assert_command_path "${nix_profile_bin}/typos"
  typos --version
}

main() {
  run_test test_commitizen_installation
  run_test test_prek_installation
  run_test test_typos_installation
}

main "$@"
