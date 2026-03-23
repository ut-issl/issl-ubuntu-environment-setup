#!/usr/bin/env bash
set -euo pipefail

profile_path="${PROFILE_PATH:?PROFILE_PATH is required}"

assert_uv_installation() {
  test -x "${profile_path}/bin/uv"
  PATH="${profile_path}/bin:${PATH}" uv --version
}

main() {
  assert_uv_installation
}

main "$@"
