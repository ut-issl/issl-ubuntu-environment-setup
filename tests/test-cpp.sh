#!/usr/bin/env bash
set -Eeuo pipefail

home_dir="${HOME_DIR:?HOME_DIR is required}"
common_dir="${COMMON_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
nix_profile_bin="${home_dir}/.nix-profile/bin"

source "${common_dir}/tests/lib.sh"

test_gcc_installation() {
  assert_command_path "${nix_profile_bin}/gcc"
  gcc --version
}

test_gxx_installation() {
  assert_command_path "${nix_profile_bin}/g++"
  g++ --version
}

test_multilib_support() {
  gcc -print-multi-lib | grep -Eq '(^|;)32'
  g++ -print-multi-lib | grep -Eq '(^|;)32'
}

test_make_installation() {
  assert_command_path "${nix_profile_bin}/make"
  make --version
}

test_cmake_installation() {
  assert_command_path "${nix_profile_bin}/cmake"
  cmake --version
}

test_clang_format_installation() {
  assert_command_path "${nix_profile_bin}/clang-format"
  clang-format --version
}

test_pkg_config_installation() {
  assert_command_path "${nix_profile_bin}/pkg-config"
  pkg-config --version
}

test_shared_clang_format_configuration() {
  cmp "${common_dir}/home-modules/cpp/clang-format.yaml" "${home_dir}/.clang-format"
}

main() {
  run_test test_gcc_installation
  run_test test_gxx_installation
  run_test test_multilib_support
  run_test test_make_installation
  run_test test_cmake_installation
  run_test test_clang_format_installation
  run_test test_pkg_config_installation
  run_test test_shared_clang_format_configuration
}

main "$@"
