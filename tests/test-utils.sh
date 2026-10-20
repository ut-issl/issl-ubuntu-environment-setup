#!/usr/bin/env bash
set -Eeuo pipefail

home_dir="${HOME_DIR:?HOME_DIR is required}"
common_dir="${COMMON_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
nix_profile_bin="${home_dir}/.nix-profile/bin"

# shellcheck source=tests/lib.sh
source "${common_dir}/tests/lib.sh"

test_fd_installation() {
  assert_command_path "${nix_profile_bin}/fd"
  fd --version
}

test_jq_installation() {
  assert_command_path "${nix_profile_bin}/jq"
  jq --version
}

test_pdftotext_installation() {
  assert_command_path "${nix_profile_bin}/pdftotext"
  pdftotext -v
}

test_pdfinfo_installation() {
  assert_command_path "${nix_profile_bin}/pdfinfo"
  pdfinfo -v
}

test_ripgrep_installation() {
  assert_command_path "${nix_profile_bin}/rg"
  rg --version
}

test_tree_installation() {
  assert_command_path "${nix_profile_bin}/tree"
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
