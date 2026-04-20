# Updating or Adding a Module or Asset

This page explains the usual workflow for updating or adding a shared asset or module in this repository.

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
4. Add or extend tests under `tests/`, and update `.github/workflows/test.yaml` if you add a new test script.

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

  xdg.configFile."issl/foo/config.toml".source = ../assets/foo/config.toml;
}
```

When updating or adding a module:

1. Update an existing file under `home-modules/`, or create a new one if needed.
2. Update `home-modules/main.nix` if you added a new module.
3. Add or update assets under `assets/` if the module needs them.
4. Update `scripts/apply.sh` if imperative wiring is required.
5. Add or extend tests under `tests/`, and update `.github/workflows/test.yaml` if you add a new test script.

If you add a new module, import it from `home-modules/main.nix`.
Add it conditionally if it should only be enabled in specific situations, similar to `zsh.nix`.

## When `apply.sh` Needs Changes

Prefer declarative integration in `home-modules/` first.

Update `scripts/apply.sh` when the setup must also modify user-controlled files
in a careful, incremental way that Home Manager alone does not cover well
in this repository's current workflow.

This usually applies when the repository must prepend include blocks, source shared files,
or preserve existing user content in files such as:

- `~/.bashrc`
- `~/.bash_profile`
- `~/.zshenv`
- `~/.cargo/config.toml`
- `~/.config/nix/nix.conf`

## Documentation Updates

After updating or adding an asset or module:

1. Update developer docs under `docs/` if the contributor workflow changes.
2. Update user docs under `docs/` if the user-visible setup behavior changes.
