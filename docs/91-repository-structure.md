# Repository Structure

This page explains how this repository is organized for development.

## Overview

This repository defines a shared Ubuntu user environment for ISSL with Nix flakes and Home Manager.

At a high level:

- `flake.nix` defines supported systems and Home Manager outputs.
- `home-modules/` defines the shared environment as composable modules.
- `assets/` stores configuration files that are deployed into the user environment.
- `scripts/` provides imperative entry points for setup and application.
- `tests/` verifies that the resulting environment and deployed files match expectations.
- `docs/` explains usage and maintenance.

## Top-Level Layout

### `flake.nix` and `flake.lock`

- `flake.nix` is the main entry point for the Nix-based configuration.
- It defines:
  - the upstream inputs such as `nixpkgs` and `home-manager`
  - supported systems
  - the shared Home Manager module exported as `homeModules.issl-common`, aliased as `homeModules.default`
  - Home Manager configurations such as `issl-common-x86_64-linux` and its Bash-only variant `issl-common-bash-only-x86_64-linux`
  - basic checks built from those configurations
- `flake.lock` pins dependency revisions for reproducibility.

### `home-modules/`

This directory contains the Home Manager modules that define the shared environment.

- `default.nix` is the aggregation point that imports every module under `common/` automatically.
- Each `*.nix` file under `common/` is responsible for one area of the environment, such as:
  - `nix.nix`
  - `shell.nix`
  - `git.nix`
  - `dev.nix`
  - `python.nix`
  - `zsh.nix`, which takes effect unless the `issl.zsh.enable` option is set to `false`,
    apart from the login shell link it deploys either way

### `assets/`

This directory contains shared configuration files copied or referenced by the setup.

Examples:

- `assets/nix/` contains shared Nix configuration such as `nix.conf`
- `assets/shell/` contains common shell environment snippets
- `assets/bash/` and `assets/zsh/` contain shell-specific startup files
- `assets/git/`, `assets/python/`, `assets/rust/`, and `assets/cpp/` contain tool-specific shared configuration

When a module installs a tool and also wants to provide a default shared config, the config file usually lives here.

### `scripts/`

This directory contains imperative shell entry points.

- `scripts/bootstrap-host.sh` prepares the host for setup by installing Nix and offering optional login shell
  registration, GitHub SSH access, and Docker Engine setup.
  - The login shell registration points `/etc/passwd` at `~/.local/state/issl/login-shell`,
    the link that `common/zsh.nix` deploys and retargets on every switch.
  - `scripts/apply.sh` sources this script and reuses that registration after the switch.
- `scripts/setup.sh` is the script-based setup entry point.
  - It prepares the host for setup through `scripts/bootstrap-host.sh`.
  - It clones this repository into the install location.
  - It is designed for users who start from a plain Ubuntu environment.
- `scripts/apply.sh` applies this repository's shared configuration into the current user environment.
  - It writes include blocks or startup hooks into user-controlled files.
  - It places shared assets under the ISSL config directory.

### `tests/`

This directory contains shell-based validation scripts for each area of the environment.

- `lib.sh` provides the shared test helpers, such as assertion logging and failure reporting.
  Every `test-*.sh` sources it.
- `run.sh` runs all the test scripts in order.
- Each `test-*.sh` corresponds to the module of the same name, such as:
  - `test-shell.sh` checks shell assets and startup file integration.
  - `test-git.sh` checks Git installation and global include behavior.
  - `test-dev.sh` checks installation of the language-agnostic development tools.
  - `test-python.sh` checks tool installation and shared config wiring.
- `pty-driver.py` drives an interactive Python REPL under a PTY for `test-python.sh`.

These tests verify that the expected tools are available and that the shared assets are deployed and referenced correctly.
In GitHub Actions they run from two places.
The script-based setup is exercised by the `script-based` job of `.github/workflows/test.yaml`,
which has only this repository as its caller and therefore lives inline.
The config-repository-based setup is exercised by the reusable `.github/workflows/test-config-repository.yaml`,
which applies one flake target of one personal config repository and then runs these tests against the result.
Every axis it is tested over — the OS, the flake target — belongs to the matrix of the calling workflow,
so this repository, the template, and each personal config repository decide their own coverage.

### `docs/`

This directory contains user-facing and developer-facing documentation.
