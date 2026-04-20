# Updating or Adding a Module or Asset

This page explains the usual workflow for updating or adding a shared asset or module in this repository.

In general, first check whether the change can be handled by extending an existing asset or module.
Add a new asset or module only when the current structure does not already provide a reasonable place for the change.

## Updating an Existing Asset

Update an existing file under `assets/` when you want to change the contents of an existing shared configuration file.

Typical examples are:

- changing shared shell defaults
- adjusting a tool config such as `.gitconfig` or `config.toml`
- updating formatter or editor settings

When updating an existing asset:

1. Edit the relevant file under `assets/`.
2. Confirm which module under `home-modules/` references that asset.
3. Check whether `scripts/apply.sh` also depends on that asset or its location.
4. Update or extend tests under `tests/` if the expected behavior changes.

If the asset path and deployment pattern stay the same, the module usually does not need structural changes.

## Adding a New Asset

Add a new file under `assets/` when the shared environment should install, copy, or reference a new configuration file.

Typical examples are:

- a new startup snippet
- a new tool config file

If the behavior can be expressed directly in Home Manager
without introducing a separate shared file, an asset is not always necessary.

When adding a new asset:

1. Create the asset file under a directory in `assets/` that matches the configuration domain.
2. Reference it from the relevant module under `home-modules/`.
3. Update `scripts/apply.sh` if the asset must also be connected to user-managed files.
4. Add or extend tests under `tests/`.

Prefer a clear directory name that matches the module name when possible, for example:

- `assets/foo/config.toml`
- `assets/foo/foo.yaml`

Common patterns in this repository are:

- `home.file` for files placed directly in the home directory
- `xdg.configFile` for files placed under `~/.config`

Examples from the current repository:

- `home.file.".clang-format".source = ../assets/cpp/clang-format.yaml;`
- `xdg.configFile."issl/git/.gitconfig".source = ../assets/git/.gitconfig;`

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
5. Add or extend tests under `tests/`.

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

## Testing and Documentation

After updating or adding an asset or module:

1. Add or extend tests under `tests/` so the behavior is checked explicitly.
2. Update developer docs if the contributor workflow changes.
3. Update user docs under `docs/` if the user-visible setup behavior changes.
