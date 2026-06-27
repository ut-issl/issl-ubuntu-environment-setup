#!/usr/bin/env bash
set -euo pipefail

common_dir="${COMMON_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"

cd "${common_dir}"

"${common_dir}/tests/test-nix.sh"
"${common_dir}/tests/test-shell.sh"
"${common_dir}/tests/test-git.sh"
"${common_dir}/tests/test-cpp.sh"
"${common_dir}/tests/test-python.sh"
"${common_dir}/tests/test-rust.sh"
"${common_dir}/tests/test-vim.sh"
