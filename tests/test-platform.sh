#!/usr/bin/env bash
set -Eeuo pipefail

home_dir="${HOME_DIR:?HOME_DIR is required}"
config_dir="${CONFIG_DIR:?CONFIG_DIR is required}"
common_dir="${COMMON_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
nix_profile_bin="${home_dir}/.nix-profile/bin"

# shellcheck source=tests/lib.sh
source "${common_dir}/tests/lib.sh"

assert_xdg_data_dirs_are_exported() {
  env -i \
    HOME="${home_dir}" \
    SHELL_ENV_PATH="${config_dir}/issl/shell/env.sh" \
    XDG_CONFIG_HOME="${config_dir}" \
    PATH="/usr/bin:/bin" \
    bash <<'EOF'
. "${SHELL_ENV_PATH}"
case ":${XDG_DATA_DIRS}:" in
*:"${HOME}/.nix-profile/share":*) ;;
*) exit 1 ;;
esac
case ":${XDG_DATA_DIRS}:" in
*:/var/lib/snapd/desktop:*) ;;
*) exit 1 ;;
esac
EOF
}

assert_gpu_integration_is_opt_in() {
  # GPU integration requires a one-time privileged setup on each host, so the
  # shared environment leaves it to personal configurations.
  test ! -e "${nix_profile_bin}/non-nixos-gpu-setup"
}

main() {
  run_assert assert_xdg_data_dirs_are_exported
  run_assert assert_gpu_integration_is_opt_in
}

main "$@"
