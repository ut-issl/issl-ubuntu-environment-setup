#!/usr/bin/env bash
set -Eeuo pipefail

home_dir="${HOME_DIR:?HOME_DIR is required}"
common_dir="${COMMON_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
nix_profile_bin="${home_dir}/.nix-profile/bin"

# shellcheck source=tests/lib.sh
source "${common_dir}/tests/lib.sh"

test_docker_client_installation() {
  assert_nix_profile_command docker
  docker --version
}

test_docker_client_plugin_dirs_wrapper() {
  grep -Fq 'DOCKER_CLI_PLUGIN_DIRS' "${nix_profile_bin}/docker"
  grep -Fq 'docker-buildx' "${nix_profile_bin}/docker"
}

test_docker_compose_installation() {
  assert_nix_profile_command docker-compose
  docker-compose version
  docker compose version
}

test_docker_compose_plugin_dirs_wrapper() {
  grep -Fq 'DOCKER_CLI_PLUGIN_DIRS' "${nix_profile_bin}/docker-compose"
  grep -Fq 'docker-buildx' "${nix_profile_bin}/docker-compose"
}

test_docker_buildx_installation() {
  assert_nix_profile_command docker-buildx
  docker-buildx version
  docker buildx version
}

test_hadolint_installation() {
  assert_nix_profile_command hadolint
  hadolint --version
}

main() {
  run_test test_docker_client_installation
  run_test test_docker_client_plugin_dirs_wrapper
  run_test test_docker_compose_installation
  run_test test_docker_compose_plugin_dirs_wrapper
  run_test test_docker_buildx_installation
  run_test test_hadolint_installation
}

main "$@"
