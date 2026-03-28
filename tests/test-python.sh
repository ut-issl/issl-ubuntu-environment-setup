#!/usr/bin/env bash
set -euo pipefail

home_dir="${HOME_DIR:?HOME_DIR is required}"
config_dir="${CONFIG_DIR:?CONFIG_DIR is required}"
nix_profile_bin="${home_dir}/.nix-profile/bin"

assert_uv_installation() {
  test -x "${nix_profile_bin}/uv"
  test "$(command -v uv)" = "${nix_profile_bin}/uv"
  uv --version
}

assert_shared_pythonrc_asset() {
  cmp --silent assets/python/pythonrc.py "${config_dir}/issl/python/pythonrc.py"
}

assert_user_python_startup_file() {
  local startup_path="${home_dir}/.python/.pythonrc.py"
  test -f "${startup_path}"
  grep -Fq '# >>> ISSL python startup >>>' "${startup_path}"
  grep -Fq '# <<< ISSL python startup <<<' "${startup_path}"
  grep -Fq 'runpy.run_path(str(shared_pythonrc), run_name="__main__")' "${startup_path}"
}

main() {
  assert_uv_installation
  assert_shared_pythonrc_asset
  assert_user_python_startup_file
}

main "$@"
