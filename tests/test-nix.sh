#!/usr/bin/env bash
set -Eeuo pipefail

home_dir="${HOME_DIR:?HOME_DIR is required}"
config_dir="${CONFIG_DIR:?CONFIG_DIR is required}"
common_dir="${COMMON_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
nix_profile_bin="${home_dir}/.nix-profile/bin"
nix_config_path="${config_dir}/nix/nix.conf"
issl_nix_config_path="${config_dir}/issl/nix/nix.conf"

# shellcheck source=tests/lib.sh
source "${common_dir}/tests/lib.sh"

test_nix_installation() {
  command -v nix >/dev/null
  nix --version
}

test_shared_nix_config() {
  cmp "${common_dir}/home-modules/nix/nix.conf" "${issl_nix_config_path}"
}

test_nix_conf_include() {
  [[ -f ${nix_config_path} ]]
  grep -Fq "!include ${issl_nix_config_path}" "${nix_config_path}"
}

test_nix_command_available_without_extra_flags() {
  env \
    HOME="${home_dir}" \
    XDG_CONFIG_HOME="${config_dir}" \
    nix profile list >/dev/null
}

test_home_manager_installation() {
  [[ -x "${nix_profile_bin}/home-manager" ]]
  [[ "$(command -v home-manager)" == "${nix_profile_bin}/home-manager" ]]
  home-manager --version
}

test_nixfmt_installation() {
  [[ -x "${nix_profile_bin}/nixfmt" ]]
  [[ "$(command -v nixfmt)" == "${nix_profile_bin}/nixfmt" ]]
  nixfmt --version
}

test_statix_installation() {
  [[ -x "${nix_profile_bin}/statix" ]]
  [[ "$(command -v statix)" == "${nix_profile_bin}/statix" ]]
  statix --help
}

test_deadnix_installation() {
  [[ -x "${nix_profile_bin}/deadnix" ]]
  [[ "$(command -v deadnix)" == "${nix_profile_bin}/deadnix" ]]
  deadnix --version
}

main() {
  run_test test_nix_installation
  run_test test_shared_nix_config
  run_test test_nix_conf_include
  run_test test_nix_command_available_without_extra_flags
  run_test test_home_manager_installation
  run_test test_nixfmt_installation
  run_test test_statix_installation
  run_test test_deadnix_installation
}

main "$@"
