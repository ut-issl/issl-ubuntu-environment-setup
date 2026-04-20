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
  - Home Manager configurations such as `issl-common-x86_64-linux`
  - basic checks built from those configurations
- `flake.lock` pins dependency revisions for reproducibility.

### `home-modules/`

This directory contains the Home Manager modules that define the shared environment.

- `main.nix` is the aggregation point.
- Each `*.nix` file under this directory is responsible for one area of the environment, such as:
  - `nix.nix`
  - `shell.nix`
  - `git.nix`
  - `cpp.nix`
  - `python.nix`
  - `rust.nix`
  - `vim.nix`
  - `zsh.nix`

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

- `scripts/setup.sh` is the bootstrap-oriented entry point.
  - It prepares prerequisites such as Nix and Git when needed.
  - It clones this repository into the install location.
  - It is designed for users who start from a plain Ubuntu environment.
- `scripts/apply.sh` applies this repository's shared configuration into the current user environment.
  - It writes include blocks or startup hooks into user-controlled files.
  - It places shared assets under the ISSL config directory.

### `tests/`

This directory contains shell-based validation scripts for each area of the environment.

Examples:

- `test-shell.sh` checks shell assets and startup file integration.
- `test-git.sh` checks Git installation and global include behavior.
- `test-python.sh` and `test-rust.sh` check tool installation and shared config wiring.
- `test-cpp.sh`, `test-vim.sh`, and `test-nix.sh` check the corresponding shared setup.

These tests verify that the expected tools are available and that the shared assets are deployed and referenced correctly.
They are executed in GitHub Actions by `.github/workflows/test.yaml`.

### `docs/`

This directory contains user-facing and developer-facing documentation.
