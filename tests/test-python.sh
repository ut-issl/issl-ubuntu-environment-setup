#!/usr/bin/env bash
set -euo pipefail

home_dir="${HOME_DIR:?HOME_DIR is required}"
config_dir="${CONFIG_DIR:?CONFIG_DIR is required}"
nix_profile_bin="${home_dir}/.nix-profile/bin"
pythonrc_path="${home_dir}/.python/.pythonrc.py"
issl_python_home="${config_dir}/issl/python"
issl_pythonrc_path="${issl_python_home}/pythonrc.py"

assert_uv_installation() {
  test -x "${nix_profile_bin}/uv"
  test "$(command -v uv)" = "${nix_profile_bin}/uv"
  uv --version
}

assert_shared_pythonrc_asset() {
  cmp --silent assets/python/pythonrc.py "${issl_pythonrc_path}"
}

assert_user_python_startup_file() {
  test -f "${pythonrc_path}"
  grep -Fq '# >>> ISSL python startup >>>' "${pythonrc_path}"
  grep -Fq '# <<< ISSL python startup <<<' "${pythonrc_path}"
  grep -Fq 'runpy.run_path(str(shared_pythonrc), run_name="__main__")' "${pythonrc_path}"
}

assert_python_startup_is_loaded() {
  local marker_dir
  marker_dir="$(mktemp -d)"

  # Drive an interactive interpreter so PYTHONSTARTUP runs, then confirm it
  # actually executed by observing the custom displayhook the startup installs.
  echo 'import sys; sys.exit(0 if sys.displayhook is not sys.__displayhook__ else 1)' |
    ISSL_PYTHON_HOME="${issl_python_home}" \
      PYTHONSTARTUP="${pythonrc_path}" \
      PYTHONHISTFILE="${marker_dir}/history" \
      TERM=dumb \
      uv run --no-project --python 3 python -i

  # The startup also wires up readline history persistence.
  test -f "${marker_dir}/history"
}

main() {
  assert_uv_installation
  assert_shared_pythonrc_asset
  assert_user_python_startup_file
  assert_python_startup_is_loaded
}

main "$@"
