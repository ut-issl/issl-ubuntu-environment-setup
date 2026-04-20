# User Guide (Package Management Practices)

This page describes the default practices for package management after setup.

When choosing how to install tools after setup, use this order by default:

1. Nix with Home Manager for globally available user-environment tools.
2. Project-local package managers (`uv`, `cargo`, `npm`, etc.) for repository-specific dependencies.
3. `apt` only when system-level integration is required (services, drivers, low-level OS packages).

## 1. Globally Available Tools

Use Nix with Home Manager for tools that should be available across your user environment.

- For a personal reproducible setup, see [User Guide (Personal Config Repository)](11-user-guide-personal-nix-config.md).
- For the `setup.sh` workflow, see [User Guide (setup.sh workflow)](12-user-guide-setup-sh.md#if-you-need-additional-tools-or-settings).

## 2. Project-Local Dependencies

Use project-local package managers for dependencies that belong to a specific repository.

### Rust

- `rustup` is available through this environment.
- Manage project-local Rust toolchains with `rustup`, and define them with `rust-toolchain.toml` in each repository.

### Python

- `uv` is available through this environment.
- Manage project-local Python environments with `uv`, and define them in `pyproject.toml` in each repository.

## 3. System-Level Packages

Use `apt` only when system-level integration is required, such as services, drivers, or low-level OS packages.
