#!/usr/bin/env bash
set -Eeuo pipefail

home_dir="${HOME_DIR:?HOME_DIR is required}"
common_dir="${COMMON_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
nix_profile_bin="${home_dir}/.nix-profile/bin"

# shellcheck source=tests/lib.sh
source "${common_dir}/tests/lib.sh"

test_fd_installation() {
  assert_nix_profile_command fd
  fd --version
}

test_jq_installation() {
  assert_nix_profile_command jq
  jq --version
}

test_pdftotext_installation() {
  assert_nix_profile_command pdftotext
  pdftotext -v
}

test_pdfinfo_installation() {
  assert_nix_profile_command pdfinfo
  pdfinfo -v
}

test_ripgrep_installation() {
  assert_nix_profile_command rg
  rg --version
}

test_tree_installation() {
  assert_nix_profile_command tree
  tree --version
}

main() {
  run_test test_fd_installation
  run_test test_jq_installation
  run_test test_pdftotext_installation
  run_test test_pdfinfo_installation
  run_test test_ripgrep_installation
  run_test test_tree_installation
}

main "$@"
