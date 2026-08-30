---
name: develop
description: >-
  Guide development of the shared ISSL environment:
  adding or updating tools, modules, assets, and tests.
  Use when asked to add a tool or package to the shared environment,
  update an existing module or asset, or modify how the environment is configured.
  Do not use for documentation-only changes, CI/CD pipeline changes,
  or dependency version bumps handled by Renovate.
---

# Develop the Shared Environment

Help update or extend the shared ISSL Ubuntu environment, one change at a time:
add a tool, update a module, add or modify an asset, or adjust the imperative setup.

Follow the conventions in `docs/92-updating-or-adding-an-asset-or-module.md`
and `docs/93-contribution-guidelines.md`.
Converse in the language the user writes in, but keep all edits (code, comments, commit messages, etc.) in English.
Leave all changes uncommitted; committing and pushing are up to the user unless explicitly requested.
Never write secrets (tokens, private keys, credentials) into the repository;
assets in this repository are deployed to every lab machine.
Never run `scripts/apply.sh`, `scripts/setup.sh`, or `home-manager switch`
against the user's real home environment without explicit approval;
use prek and `nix flake check --all-systems` for local validation instead.

Before starting, verify that `nix` is available (`command -v nix`).
Nix is required for developing this repository;
changes cannot be validated without it, and bugs here affect the entire lab.
If Nix is not available, stop and ask the user to set it up first.

## 1. Understand the request

Identify what the user wants: a new tool in the shared environment,
a change to an existing tool's configuration, a new asset, or a structural change.
Ask only if the request is ambiguous.

## 2. Check what already exists

Before adding anything, scan the actual repository state (not the docs, which may lag):

- `home-modules/common/` for existing modules that already cover the tool or area.
  Every file there is imported automatically by `home-modules/default.nix`.
- `home-modules/common/zsh.nix` for how a module makes itself conditional
  by declaring an option and gating its `config` with `lib.mkIf`.
- `assets/` for existing configuration files.
- `tests/` for existing test coverage.
- `scripts/apply.sh` for existing imperative wiring.

If there is already a related module or asset, update it rather than creating a new one.

## 3. Research the package and its options

For a new tool:

- Settle first whether the package is a graphical application, and stop there if it is:
  say that it does not belong in the shared environment, and do not go on to the license check or to a placement.
  `docs/92-updating-or-adding-an-asset-or-module.md` § "Updating or Adding a Module" has the reasons.
  Point the user to `docs/13-package-management-practices.md` rather than to a particular alternative:
  whether such an application can live in a personal config repository
  or has to stay with the distribution depends on the host integration it needs.
- Look the package up in nixpkgs at the pinned revision:
  read the `nixpkgs` entry's `locked.rev` from `flake.lock` and run `nix search github:NixOS/nixpkgs/<rev> <name>`.
- `flake.nix` declares `x86_64-linux` and `aarch64-linux`, and both have to keep evaluating.
  Guard a package that is meaningful on only one of them on the platform,
  as `common/cpp.nix` does with `pkgs.stdenv.hostPlatform.isx86_64` for the multilib GCC.
- `home-modules/common/nix.nix` sets `nixpkgs.config.allowUnfree = true`,
  so an unfree package can be added without a flake change.
  Because that setting also applies to every personal config repository importing this one,
  check the package's license terms and get an explicit yes from the user before adding one,
  and state in the pull request why it is worth distributing to all users under those terms.
- If the package is not in nixpkgs, report honestly and let the user decide.
  Never add flake inputs or overlays without an explicit yes.

## 4. Decide where the change goes

Follow the conventions in `docs/92-updating-or-adding-an-asset-or-module.md`.

This repository deliberately does not use Home Manager's `programs.<tool>` options
that generate user-level config files (e.g. `~/.gitconfig`, `~/.bashrc`).
Shared configuration is deployed under `~/.config/issl/` and included or sourced from user-managed files instead,
to preserve user flexibility and avoid conflicts with both setup modes.

- **Existing module covers this area**: update that module.
- **New tool with no settings**: add to `home.packages` in an existing module
  that covers the same area, or create a new module if it represents a distinct area.
- **New tool with shared configuration**: create a dedicated module `home-modules/common/<tool>.nix`
  and place the config file under `assets/<tool>/`.
  Use `xdg.configFile."issl/<tool>/..."` to deploy shared configuration
  under the ISSL config directory,
  `xdg.stateFile."issl/..."` for a path the environment maintains rather than the user edits
  (`zsh.nix` deploys the login shell link that way),
  or `home.file` when the file must live at a fixed path outside those directories.
- **A Home Manager option rather than a package**: a module may set options directly,
  as `common/platform.nix` does for `targets.genericLinux`.
  Use `lib.mkDefault` for an option a personal config repository should be able to override,
  and a plain definition for one that has to hold for everyone.
  Choose a default that asks nothing of the user, and within that constraint follow what most users want.
- **New module**: create the file under `home-modules/common/` and track it with Git.
  It is imported automatically.
  Reuse the existing `issl.zsh.enable` option where it fits;
  introducing a new condition means declaring another option and gating `config` with `lib.mkIf`,
  and it also requires changes to `flake.nix` (configurations, checks) and the CI test matrix —
  confirm with the user before going that route.

If the change also requires imperative wiring
(connecting shared config to user-managed files such as `~/.bashrc` or `~/.cargo/config.toml`),
`scripts/apply.sh` will need updating as well.
But prefer declarative integration in `home-modules/` first,
and update `scripts/apply.sh` only when that is not enough.
See `docs/92-updating-or-adding-an-asset-or-module.md` § "When `apply.sh` Needs Changes" for guidance.

If more than one placement is reasonable, present the options briefly with a recommendation
and let the user choose before editing.

## 5. Implement the change

Match the style of the existing modules.
Formatting is enforced by nixfmt via the pre-commit hooks.

For `scripts/apply.sh`, if changes are needed:

- Use the `prepend_block_once` helper for wiring shared config into user-managed files.
- Follow the existing marker pattern (`# >>> ISSL <name> >>>` / `# <<< ISSL <name> <<<`).

## 6. Add or update tests

Every module should have corresponding test coverage under `tests/`.

Tests run in CI against a freshly applied environment
(the `script-based` job of `.github/workflows/test.yaml` and the reusable
`.github/workflows/test-config-repository.yaml` both set `HOME_DIR`/`CONFIG_DIR`/`STATE_DIR` and run `tests/run.sh`).
Do not try to run them locally unless this machine has the shared environment applied;
local validation is prek plus the Nix validation in step 7,
which can confirm installed binaries and deployed files without applying anything.

If a test file for this area already exists (e.g. `tests/test-<tool>.sh`), extend it.
If not, create a new `tests/test-<tool>.sh` following the existing pattern:

1. Copy the header from the closest existing test:
   `set -Eeuo pipefail`, the required environment variable guards
   (`HOME_DIR:?` always; `CONFIG_DIR:?` when inspecting deployed config or user-managed file wiring;
   `STATE_DIR:?` when inspecting what a module deploys under `~/.local/state/issl/`),
   the `COMMON_DIR` fallback, and `nix_profile_bin="${home_dir}/.nix-profile/bin"`.
   Then source `tests/lib.sh` for the `run_assert` helper
   and the failure-reporting ERR trap (which needs the `-E` in `set -Eeuo pipefail`).
2. Define assertion functions (e.g. `assert_<tool>_installation`, `assert_<tool>_config`).
3. Call them via `run_assert` in a `main` function.
4. Make the script executable.
5. Register the new test script in `tests/run.sh` by adding its name to the loop list.

For a module that takes effect only in specific configurations (like `zsh.nix`),
gate its assertions on the corresponding environment variable
inside the relevant test script (see `ISSL_ENABLE_ZSH` in `test-shell.sh`)
instead of adding a separate unconditional script.

Common assertion patterns:

- **Tool installation**: check `test -x "${nix_profile_bin}/<binary>"`
  and verify `command -v` resolves to the Nix profile path.
- **Asset deployment**: use `cmp` to verify the deployed file matches the source under `assets/`.
- **Config wiring**: use `grep -Fq` to check that include or source lines are present in user-managed files.

## 7. Validate

Run validation in this order:

1. Run `prek run --files <changed files> --skip no-commit-to-branch` and fix what it reports.
   If `prek` is not on PATH, use `uvx prek` instead.
2. Run the Nix validation of `docs/92-updating-or-adding-an-asset-or-module.md` § "Validating Changes":
   stage the new files, run the flake checks,
   then build the activation packages and inspect the installed binaries and deployed files.
   Build for the system of this machine, not the one in the example command.
   Remove the `result-*` symlinks when done.

## 8. Wrap up

Summarize what was changed, what was validated, and what was skipped.

If the change affects contributor workflow or user-visible setup behavior,
update the relevant documentation under `docs/` as part of this task
(see `docs/92-updating-or-adding-an-asset-or-module.md` § "Documentation Updates").

If the user later asks for a commit or PR,
follow the Conventional Commits format described in `docs/93-contribution-guidelines.md`,
and suggest an appropriate version bump label (`update::major`, `update::minor`, or `update::patch`)
for the pull request.
Leave all changes uncommitted until then.
