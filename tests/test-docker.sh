#!/usr/bin/env bash
set -Eeuo pipefail

home_dir="${HOME_DIR:?HOME_DIR is required}"
common_dir="${COMMON_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
nix_profile_bin="${home_dir}/.nix-profile/bin"

# shellcheck source=tests/lib.sh
source "${common_dir}/tests/lib.sh"

assert_docker_client_installation() {
  test -x "${nix_profile_bin}/docker"
  test "$(command -v docker)" = "${nix_profile_bin}/docker"
  docker --version
}

assert_docker_compose_installation() {
  test -x "${nix_profile_bin}/docker-compose"
  test "$(command -v docker-compose)" = "${nix_profile_bin}/docker-compose"
  docker-compose version
}

assert_docker_buildx_installation() {
  test -x "${nix_profile_bin}/docker-buildx"
  test "$(command -v docker-buildx)" = "${nix_profile_bin}/docker-buildx"
  docker-buildx version
}

main() {
  run_assert assert_docker_client_installation
  run_assert assert_docker_compose_installation
  run_assert assert_docker_buildx_installation
}

main "$@"
