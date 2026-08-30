# Setup with a Personal Config Repository

This guide covers the workflow of maintaining a personal Nix configuration repository with Home Manager
that imports this repository.

## What This Path Gives You

Your own repository describes your whole user environment as code:
the shared ISSL environment this repository provides, and your personal tools and settings on top of it.
Applying it on another machine reproduces that environment,
and every change to it is reviewable and revertible like any other code.

Choose this path if you want personal customization with reproducibility across machines and reinstallations,
and are willing to maintain a repository of your own.
If the shared environment is mostly sufficient and extra tools are occasional,
[script-based setup](12-script-based-setup.md) is the lighter choice.

## How the Repositories Relate

Three repositories are involved:

- **This repository** provides the shared ISSL environment as a Home Manager module.
  A personal config repository consumes it as a flake input pinned to a release tag.
- **[`ut-issl/personal-nix-config-template`](https://github.com/ut-issl/personal-nix-config-template)**
  is the starting point: a personal config repository that already imports this repository,
  with the scaffolding and the agent skills in place.
- **Your own repository**, created from that template, is yours to change.

## Getting Started

Create your repository from the template with the **Use this template** button on GitHub,
then follow the Getting Started section of its README.

The section's first step runs `bootstrap-host.sh` from a release of this repository.
The script installs Nix, starts `nix-daemon` on systems without systemd,
and offers to set up GitHub SSH access and the host Docker Engine.
It is the only part of the setup that needs privileges,
and it is the same script the [script-based setup](12-script-based-setup.md) runs.

## What the Shared Configuration Provides

A personal config repository imports the Home Manager module this repository exports,
named `homeModules.issl-common` and aliased as `homeModules.default`.

These options are yours to set:

- `issl.zsh.enable` (default: `true`) installs and configures Zsh.
  Set it to `false` for a Bash-only environment; the shared Bash configuration applies either way.
- `targets.genericLinux.gpu.enable` (default: `false`) turns on the GPU driver integration
  that Nix-built applications rendering through OpenGL need, and asks for a one-time privileged setup on each machine.
  See [package management practices](13-package-management-practices.md#gui-applications).

The shared module also decides the following for every configuration that imports it:

- Shared configuration files are deployed under `~/.config/issl`,
  for the personal modules to source or include them from the files Home Manager manages.
- `nixpkgs.config.allowUnfree` is set to `true`,
  so unfree packages you add in your own repository install without extra setup.
  See [package management practices](13-package-management-practices.md#unfree-packages).
- `targets.genericLinux` is enabled, so the desktop entries of the packages you install are visible to the desktop environment.
- Your login shell follows `issl.zsh.enable`,
  through the link `~/.local/state/issl/login-shell` that the shared module retargets on every switch.
  `bootstrap-host.sh` registers that link in `/etc/passwd` once, because Home Manager cannot edit `/etc/passwd` itself.
  If you decline that step, a switch with Zsh enabled tells you the command that hands the login shell over.

This repository also exports the reusable workflow `.github/workflows/test-config-repository.yaml`.
It applies one flake target of a personal config repository and runs the environment tests against the result.
Every axis the tests run over is an input, so each repository decides its own coverage:
`flake-target` selects the configuration to apply, `zsh-enabled` tells the tests which shell to expect,
and `os` selects the runner.

## Keeping Up to Date

Updates reach your repository through two routes:

- **Releases of this repository** arrive when you point your flake input at a newer release tag,
  by hand or through Renovate if you enable it.
  A release that requires a change on your side says so in its notes.
- **Improvements to the template** arrive through its [`sync-template` agent skill](https://github.com/ut-issl/personal-nix-config-template#sync-template),
  which merges the template's later commits into your repository and opens a pull request.

Taking a new release of this repository does not require a sync with the template.
A sync usually brings a newer release with it, however: the template pins this repository too,
so its commits include the bump and any change the release called for.

## Migrating from the Script-Based Setup

Moving from [script-based setup](12-script-based-setup.md) to your own repository does not need a fresh machine.
Nix is already installed, so the bootstrap step usually has nothing left to do.
Run it again if you turned down its GitHub SSH or Docker Engine setup and need it now.

Before you apply your own configuration, list what you installed imperatively:

```bash
nix profile list
```

Add those packages to `home.packages` in your own modules and apply the configuration,
then remove them from the profile so that nothing is installed twice:

```bash
nix profile remove <name>
```

The clone that the setup script made is no longer applied once your own configuration takes over.
Remove it when nothing else refers to it; unless `INSTALL_DIR` was set, it is at `${XDG_DATA_HOME:-$HOME/.local/share}/issl/ubuntu-environment-setup`.
