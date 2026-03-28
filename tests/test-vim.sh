#!/usr/bin/env bash
set -euo pipefail

home_dir="${HOME_DIR:?HOME_DIR is required}"
nix_profile_bin="${home_dir}/.nix-profile/bin"

assert_vim_installation() {
  test -x "${nix_profile_bin}/vim"
  test "$(command -v vim)" = "${nix_profile_bin}/vim"
  vim --version
}

main() {
  assert_vim_installation
}

main "$@"
