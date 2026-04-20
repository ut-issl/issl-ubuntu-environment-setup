# Adding a New Module or Asset

This page explains the usual workflow for adding a new shared module or asset to this repository.

## When to Add a New Module

Add a new file under `home-modules/` when you want to introduce a new area of responsibility, such as:

- a new toolchain
- a new editor or CLI tool group
- a new shared configuration domain

If the change is small and clearly belongs to an existing area, extend the existing module instead of creating a new one.

## When to Add a New Asset

Add a file under `assets/` when the shared environment should install, copy, or reference a concrete configuration file.

Typical examples are:

- shell startup snippets
- tool config files such as `.gitconfig` or `config.toml`
- shared defaults such as formatter settings

If the behavior can be expressed directly in Home Manager
without introducing a separate shared file, an asset is not always necessary.

## Adding a New Module

### 1. Create the module file

Add a new file under `home-modules/`, for example `home-modules/foo.nix`.

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

### 2. Import the module from `main.nix`

Update `home-modules/main.nix` so the new module becomes part of the shared environment.

- Add it unconditionally if it is part of the standard baseline.
- Add it conditionally if it should only be enabled in specific situations, similar to `zsh.nix`.

### 3. Add a test

Add or extend a shell test under `tests/` so the new behavior is checked explicitly.

Typical checks are:

- the expected executable is available from the Home Manager profile
- the shared asset is deployed to the expected location
- the user's startup or include file references the shared asset when applicable

## Adding a New Asset

### 1. Create the asset file

Place the file under a directory in `assets/` that matches the domain of the configuration, for example:

- `assets/foo/config.toml`
- `assets/foo/foo.rc`

Prefer a clear directory name that matches the module name when possible.

### 2. Reference the asset from a module

Wire the asset into the user environment from the relevant file under `home-modules/`.

Common patterns in this repository are:

- `home.file` for files placed directly in the home directory
- `xdg.configFile` for files placed under `~/.config`

Examples from the current repository:

- `home.file.".clang-format".source = ../assets/cpp/clang-format.yaml;`
- `xdg.configFile."issl/git/.gitconfig".source = ../assets/git/.gitconfig;`

### 3. Update `apply.sh` if imperative wiring is required

Some assets only need to be deployed by Home Manager.
Others also require imperative integration into existing user-managed files.

Update `scripts/apply.sh` when the new asset must also be connected to files such as:

- `~/.bashrc`
- `~/.bash_profile`
- `~/.zshenv`
- `~/.cargo/config.toml`
- `~/.config/nix/nix.conf`

This is needed when the repository must prepend include blocks, source shared files, or preserve existing user content.

### 4. Add a test

Add or extend a test under `tests/` that verifies the asset is deployed and referenced correctly.

## Choosing Between Declarative and Imperative Integration

Prefer declarative integration in `home-modules/` first.

Only add logic to `scripts/apply.sh` when the setup must modify user-controlled files
in a careful, incremental way that Home Manager alone does not cover well
in this repository's current workflow.

## Documentation Updates

If the new module or asset changes how contributors should work in this repository, update the developer docs as well.

If it changes user-visible setup behavior, update the relevant user guide under `docs/`.
