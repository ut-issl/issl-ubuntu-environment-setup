#!/usr/bin/env bash
set -euo pipefail

home_dir="${HOME_DIR:?HOME_DIR is required}"
config_dir="${CONFIG_DIR:?CONFIG_DIR is required}"
nix_config_path="${config_dir}/nix/nix.conf"
issl_nix_config_path="${config_dir}/issl/nix/nix.conf"

assert_nix_installation() {
  command -v nix >/dev/null
  nix --version
}

assert_shared_nix_config() {
  cmp --silent assets/nix/nix.conf "${issl_nix_config_path}"
}

assert_nix_conf_include() {
  grep -Fq '# >>> ISSL nix config >>>' "${nix_config_path}"
  grep -Fq "# <<< ISSL nix config <<<" "${nix_config_path}"
  grep -Fq "!include ${issl_nix_config_path}" "${nix_config_path}"
}

assert_nix_command_available_without_extra_flags() {
  env \
    HOME="${home_dir}" \
    XDG_CONFIG_HOME="${config_dir}" \
    nix profile list >/dev/null
}

main() {
  assert_nix_installation
  assert_shared_nix_config
  assert_nix_conf_include
  assert_nix_command_available_without_extra_flags
}

main "$@"
