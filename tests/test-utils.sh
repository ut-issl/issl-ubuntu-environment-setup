#!/usr/bin/env bash
set -Eeuo pipefail

home_dir="${HOME_DIR:?HOME_DIR is required}"
common_dir="${COMMON_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
nix_profile_bin="${home_dir}/.nix-profile/bin"

# shellcheck source=tests/lib.sh
source "${common_dir}/tests/lib.sh"

assert_fd_installation() {
  test -x "${nix_profile_bin}/fd"
  test "$(command -v fd)" = "${nix_profile_bin}/fd"
  fd --version
}

assert_jq_installation() {
  test -x "${nix_profile_bin}/jq"
  test "$(command -v jq)" = "${nix_profile_bin}/jq"
  jq --version
}

assert_pdftotext_installation() {
  test -x "${nix_profile_bin}/pdftotext"
  test "$(command -v pdftotext)" = "${nix_profile_bin}/pdftotext"
  pdftotext -v
}

assert_pdfinfo_installation() {
  test -x "${nix_profile_bin}/pdfinfo"
  test "$(command -v pdfinfo)" = "${nix_profile_bin}/pdfinfo"
  pdfinfo -v
}

assert_ripgrep_installation() {
  test -x "${nix_profile_bin}/rg"
  test "$(command -v rg)" = "${nix_profile_bin}/rg"
  rg --version
}

assert_tree_installation() {
  test -x "${nix_profile_bin}/tree"
  test "$(command -v tree)" = "${nix_profile_bin}/tree"
  tree --version
}

main() {
  run_assert assert_fd_installation
  run_assert assert_jq_installation
  run_assert assert_pdftotext_installation
  run_assert assert_pdfinfo_installation
  run_assert assert_ripgrep_installation
  run_assert assert_tree_installation
}

main "$@"
