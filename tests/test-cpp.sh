#!/usr/bin/env bash
set -euo pipefail

home_dir="${HOME_DIR:?HOME_DIR is required}"
nix_profile_bin="${home_dir}/.nix-profile/bin"

assert_gcc_installation() {
  test -x "${nix_profile_bin}/gcc"
  test "$(command -v gcc)" = "${nix_profile_bin}/gcc"
  gcc --version
}

assert_gxx_installation() {
  test -x "${nix_profile_bin}/g++"
  test "$(command -v g++)" = "${nix_profile_bin}/g++"
  g++ --version
}

assert_multilib_support() {
  gcc -print-multi-lib | grep -Eq '(^|;)32'
  g++ -print-multi-lib | grep -Eq '(^|;)32'
}

assert_make_installation() {
  test -x "${nix_profile_bin}/make"
  test "$(command -v make)" = "${nix_profile_bin}/make"
  make --version
}

assert_cmake_installation() {
  test -x "${nix_profile_bin}/cmake"
  test "$(command -v cmake)" = "${nix_profile_bin}/cmake"
  cmake --version
}

assert_clang_format_installation() {
  test -x "${nix_profile_bin}/clang-format"
  test "$(command -v clang-format)" = "${nix_profile_bin}/clang-format"
  clang-format --version
}

main() {
  assert_gcc_installation
  assert_gxx_installation
  assert_multilib_support
  assert_make_installation
  assert_cmake_installation
  assert_clang_format_installation
}

main "$@"
