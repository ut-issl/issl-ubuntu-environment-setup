#!/usr/bin/env bash
set -Eeuo pipefail

home_dir="${HOME_DIR:?HOME_DIR is required}"
config_dir="${CONFIG_DIR:?CONFIG_DIR is required}"
common_dir="${COMMON_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
nix_profile_bin="${home_dir}/.nix-profile/bin"
pythonrc_path="${config_dir}/python/pythonrc.py"
issl_python_home="${config_dir}/issl/python"
issl_pythonrc_path="${issl_python_home}/pythonrc.py"

# shellcheck source=tests/lib.sh
source "${common_dir}/tests/lib.sh"

_is_python_ge_3_13() {
  local py_version major minor
  py_version="$(uv run --no-project --python 3 python -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
  IFS=. read -r major minor <<<"${py_version}"
  [ "${major}" -gt 3 ] || { [ "${major}" -eq 3 ] && [ "${minor}" -ge 13 ]; }
}

_is_libedit() {
  local result
  result="$(uv run --no-project --python 3 python -c '
import sys
try:
    import readline
except ImportError:
    print("no"); raise SystemExit
if sys.version_info >= (3, 13):
    print("yes" if getattr(readline, "backend", "") == "editline" else "no")
else:
    print("yes" if "libedit" in getattr(readline, "__doc__", "") else "no")
')"
  [ "${result}" = "yes" ]
}

_python_exe() {
  uv run --no-project --python 3 python -c 'import sys; print(sys.executable)'
}

assert_uv_installation() {
  test -x "${nix_profile_bin}/uv"
  test "$(command -v uv)" = "${nix_profile_bin}/uv"
  uv --version
}

assert_shared_pythonrc_asset() {
  cmp "${common_dir}/assets/python/pythonrc.py" "${issl_pythonrc_path}"
}

assert_user_python_startup_file() {
  test -f "${pythonrc_path}"
  grep -Fq 'runpy.run_path(str(shared_pythonrc), run_name="__main__")' "${pythonrc_path}"
}

assert_python_startup_is_loaded() {
  local marker_dir
  marker_dir="$(mktemp -d)"

  echo 'import sys; sys.exit(0 if sys.displayhook is not sys.__displayhook__ else 1)' |
    ISSL_PYTHON_HOME="${issl_python_home}" \
      PYTHONSTARTUP="${pythonrc_path}" \
      PYTHON_HISTORY="${marker_dir}/history" \
      TERM=dumb \
      uv run --no-project --python 3 python -i

  test -f "${marker_dir}/history" || test -f "${marker_dir}/history.editline"
}

assert_python_startup_pyrepl_history() {
  if ! _is_python_ge_3_13; then
    echo "Skipping: Python < 3.13 (no pyrepl)"
    return 0
  fi

  local hist_dir python_exe
  hist_dir="$(mktemp -d)"
  python_exe="$(_python_exe)"

  ISSL_PYTHON_HOME="${issl_python_home}" \
    PYTHONSTARTUP="${pythonrc_path}" \
    PYTHON_HISTORY="${hist_dir}/history" \
    TERM=xterm \
    uv run --no-project --python 3 python "${common_dir}/tests/pty-driver.py" "${python_exe}"

  test -f "${hist_dir}/history"
  grep -q "1+1" "${hist_dir}/history"

  if _is_libedit; then
    test ! -f "${hist_dir}/history.editline"
  fi
}

assert_python_startup_basic_repl_libedit_history() {
  if ! _is_python_ge_3_13; then
    echo "Skipping: Python < 3.13 (no basic REPL redirect needed)"
    return 0
  fi
  if ! _is_libedit; then
    echo "Skipping: readline backend is not libedit"
    return 0
  fi

  local hist_dir python_exe
  hist_dir="$(mktemp -d)"
  python_exe="$(_python_exe)"

  ISSL_PYTHON_HOME="${issl_python_home}" \
    PYTHONSTARTUP="${pythonrc_path}" \
    PYTHON_HISTORY="${hist_dir}/history" \
    PYTHON_BASIC_REPL=1 \
    TERM=xterm \
    uv run --no-project --python 3 python "${common_dir}/tests/pty-driver.py" "${python_exe}"

  test -f "${hist_dir}/history.editline"
  grep -q "1+1" "${hist_dir}/history.editline"
  test ! -f "${hist_dir}/history"
}

main() {
  run_assert assert_uv_installation
  run_assert assert_shared_pythonrc_asset
  run_assert assert_user_python_startup_file
  run_assert assert_python_startup_is_loaded
  run_assert assert_python_startup_pyrepl_history
  run_assert assert_python_startup_basic_repl_libedit_history
}

main "$@"
