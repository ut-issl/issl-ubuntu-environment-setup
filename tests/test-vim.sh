#!/usr/bin/env bash
set -Eeuo pipefail

home_dir="${HOME_DIR:?HOME_DIR is required}"
common_dir="${COMMON_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
nix_profile_bin="${home_dir}/.nix-profile/bin"

# shellcheck source=tests/lib.sh
source "${common_dir}/tests/lib.sh"

assert_vim_installation() {
  test -x "${nix_profile_bin}/vim"
  test "$(command -v vim)" = "${nix_profile_bin}/vim"
  vim --version
}

main() {
  run_assert assert_vim_installation
}

main "$@"
