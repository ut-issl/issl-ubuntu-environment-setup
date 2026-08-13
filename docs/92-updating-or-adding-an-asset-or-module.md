# Updating or Adding an Asset or Module

This page explains the usual workflow for updating or adding a shared asset or module in this repository.

## Agent Skill

This repository ships a `develop` skill for coding agents that support [Agent Skills](https://agentskills.io)
(e.g. Codex or Claude Code).
Invoke it with `$develop` in Codex or `/develop` in Claude Code.

It assists the workflow on this page interactively —
from checking what already exists and researching nixpkgs
to editing the modules and assets, extending the tests, and validating the result.
State what you want when invoking it (e.g. `$develop add lazygit`).

It leaves every change uncommitted, so you review the result before committing it yourself.

## Updating or Adding an Asset

Changes to `assets/` are needed when the shared configuration files themselves should change.

Typical examples are:

- changing the contents of an existing shared configuration file
- a new startup snippet
- a new tool config file
- updated formatter or editor settings

If there is already a related file under `assets/`, update that existing asset.
If there is no reasonable existing asset for the change, add a new one.

If the behavior can be expressed directly in Home Manager
without introducing a separate shared file, an asset is not always necessary.

When updating or adding an asset:

1. Update an existing file under `assets/`, or create a new one if needed.
2. Update the relevant module under `home-modules/` so the asset is deployed.
3. Update `scripts/apply.sh` if the asset must also be connected to user-managed files.
4. Add or extend tests under `tests/`, and update `tests/run.sh` if you add a new test script.

For how to reflect the asset in Home Manager, see [Updating or Adding a Module](#updating-or-adding-a-module).

## Updating or Adding a Module

Changes to `home-modules/` are needed when the shared Home Manager configuration should change.

Typical examples are:

- a new toolchain
- a new tool in an existing toolchain or tool group
- a new asset that should be deployed by a module
- a change to tool settings that are configured directly through Home Manager
- a change to how an existing asset is deployed

If there is already a related file under `home-modules/`, update that existing module.
If there is no reasonable existing module for the change, add a new one.

In most cases, the module should do one or both of the following:

- add packages through `home.packages`
- deploy shared files through `home.file` or `xdg.configFile`

For example:

```nix
{ pkgs, ... }:

{
  home.packages = [ pkgs.foo ];

  home.file.".foo.rc".source = ../../assets/foo/foo.rc;
  xdg.configFile."issl/foo/config.toml".source = ../../assets/foo/config.toml;
}
```

A module may also set Home Manager options directly, as `common/platform.nix` does for `targets.genericLinux`.
Use `lib.mkDefault` for an option a personal config repository should be able to override,
and a plain definition for one that has to hold for everyone, as `programs.home-manager.enable` does in `common/nix.nix`.
Two plain definitions of an option carry equal priority; a boolean then conflicts instead of one overriding the other.
A mergeable option such as `nixpkgs.config` combines them instead, so a personal definition can still merge into it.

Choose a default that asks nothing of the user:
`targets.genericLinux.gpu.enable` is off because enabling it asks every machine for a privileged one-time setup.

`home-modules/common/nix.nix` sets `nixpkgs.config.allowUnfree = true` for the whole configuration,
so a module may add a package with an unfree license.
Because that setting also applies to everyone who imports this repository,
state in the pull request why the package is worth distributing to all users under its license terms.

The shared environment installs no graphical application, and a new one does not belong here either.
A Nix build often loses host integration that the package of the distribution keeps, in ways that vary by toolkit.
An AppArmor profile attaches to an executable path.
A Chromium- or Electron-based application built by Nix never matches the profile that grants it a user namespace,
so it fails to start on Ubuntu 24.04 and later, where unprivileged user namespaces are restricted by default.
The ibus input methods do not reach a Nix-built GTK3 application,
and OpenGL rendering needs `targets.genericLinux.gpu.enable`, which is off here.
Where such an application belongs instead depends on the host integration it needs.
[Package management practices](13-package-management-practices.md) covers both cases:
a personal config repository, and the distribution when that integration cannot be given up.

When updating or adding a module:

1. Update an existing file under `home-modules/common/`, or create a new one if needed.
2. Add or update assets under `assets/` if the module needs them.
3. Update `scripts/apply.sh` if imperative wiring is required.
4. Add or extend tests under `tests/`, and update `tests/run.sh` if you add a new test script.

A new file under `home-modules/common/` is picked up automatically.
It must be tracked by Git, because a flake only sees tracked files.
If a module should only take effect in specific situations,
declare an option for it and gate its `config` with `lib.mkIf`, following `common/zsh.nix`.

## When `apply.sh` Needs Changes

Prefer declarative integration in `home-modules/` first,
and update `scripts/apply.sh` only when that is not enough.

For settings where user flexibility should be preserved,
this repository avoids direct Home Manager ownership of user-managed config files.
Instead, the shared ISSL-managed configuration is typically imported or sourced
from those user-managed files.

Update `scripts/apply.sh` when the setup must connect the shared configuration
to user-managed files in a careful, incremental way that preserves existing user content.
In practice, this usually means adding include blocks or source commands to user-managed files such as:

- `~/.bashrc`
- `~/.zshenv`
- `~/.cargo/config.toml`
- `~/.config/nix/nix.conf`

## Validating Changes

Validate a change in three steps:
first run the pre-commit hooks, then confirm that it evaluates and builds,
and finally inspect what it actually produces.

Nix reads this repository through Git, so stage a new file before you validate:

```console
git add -N <new files>
```

This records an intent to add and creates no commit.
Without it, a new module fails to evaluate because Nix does not see the file,
and a new test is silently left out.

1. Run the pre-commit hooks:

   ```console
   prek run --files <changed files>
   ```

   This applies the formatters and the linters to the changed files.
   For Nix files, nixfmt formats the changed files, while deadnix and statix check the whole repository.
   See [Contribution Guidelines](93-contribution-guidelines.md) for how to install the hooks.

2. Run the checks:

   ```console
   nix flake check --show-trace
   ```

   This builds the activation packages for both the Bash-only and the Zsh configuration,
   and catches Nix evaluation errors and build failures.

3. Build the activation packages to inspect the result:

   ```console
   nix build .#checks.x86_64-linux.home --out-link result-home
   nix build .#checks.x86_64-linux.home-zsh --out-link result-home-zsh
   ```

   Replace `x86_64-linux` with `aarch64-linux` to inspect the result for that architecture.

   Each build result contains what users receive:

   - `result-home/home-path/bin` holds the binaries the configuration installs.
   - `result-home/home-files` holds the files deployed through `home.file` and `xdg.configFile`,
     so a deployed asset can be compared against its source under `assets/` with `cmp`.
   - `result-home/activate` is the activation script that Home Manager runs on `switch`.

   The checks use the fixed username `issl` and home directory `/tmp/issl-home`,
   so paths under the build result refer to that home directory rather than yours.

## Documentation Updates

After updating or adding an asset or module:

1. Update developer docs under `docs/` if the contributor workflow changes.
2. Update user docs under `docs/` if the user-visible setup behavior changes.
