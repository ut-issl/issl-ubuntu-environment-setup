# shellcheck shell=bash
# Shared helpers for the ISSL environment tests.
#
# Sourcing scripts must enable errtrace (set -E) so the ERR trap below also
# fires for failures inside functions.

# Report the location and command of the first failing assertion.
# shellcheck disable=SC2317  # invoked via the ERR trap, not directly.
_issl_test_failed() {
  local status=$?
  printf 'FAILED: %s:%s: %s (exit %s)\n' \
    "${BASH_SOURCE[1]##*/}" "${BASH_LINENO[0]}" "${BASH_COMMAND}" "${status}" >&2
}
trap _issl_test_failed ERR

# Run a named assertion, logging it so progress is visible in the test output.
run_assert() {
  printf -- '-- %s\n' "${1}"
  "$@"
}
