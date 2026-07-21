# Script-Based Setup

This guide covers the quick-setup workflow using the setup script provided by this repository.

## Initial Setup

Run:

```bash
bash <(curl -fsSL https://github.com/ut-issl/issl-ubuntu-environment-setup/releases/latest/download/setup.sh)
```

To pin setup to a fixed release, replace `latest` with a tag such as `v0.4.2`:

```bash
bash <(curl -fsSL https://github.com/ut-issl/issl-ubuntu-environment-setup/releases/download/v0.4.2/setup.sh)
```

Each release's `setup.sh` defaults to installing that same release,
so pinning the download tag also pins the installed environment.

To override setup variables, set environment variables before running the command.
For example, set `REPO_REF=main` for development, or set `INSTALL_DIR` to choose another install location:

```bash
INSTALL_DIR="$HOME/.issl-ubuntu-environment-setup" \
bash <(curl -fsSL https://github.com/ut-issl/issl-ubuntu-environment-setup/releases/latest/download/setup.sh)
```

After setup, open a new shell.

### Repository Overrides

Set `REPO_URL` and `REPO_REF` to install from another GitHub repository or ref.
For streamed setup, bootstrap script selection has the following limits:

- HTTPS public forks and mirrors are supported.
- SSH private repositories can be used as the install target,
  but `bootstrap-host.sh` is downloaded from the public shared repository.
- Private fork-specific `bootstrap-host.sh` files are not supported by streamed setup.
- To use a private fork-specific bootstrap script, clone the repository first and run its local `scripts/setup.sh`.

### Optional Docker Engine Setup

The shared Home Manager configuration installs the Docker CLI tools.
Interactive setup prompts to install the host Docker Engine with yes as the default answer.
Non-interactive setup skips Docker Engine unless you opt in explicitly:

```bash
ISSL_INSTALL_DOCKER=yes \
bash <(curl -fsSL https://github.com/ut-issl/issl-ubuntu-environment-setup/releases/latest/download/setup.sh)
```

Set `ISSL_INSTALL_DOCKER=no` to skip the prompt explicitly.

## If You Need Additional Tools or Settings

This workflow assumes the shared setup is usually sufficient.
If you later need something more, choose one of the following paths.

### 1. If it should be shared within ISSL

If the tool or setting should be part of the standard ISSL environment, please reflect it in this repository.
Open a pull request, or contact the maintainers if you are not going to prepare the change yourself.

### 2. If it is personal, but you want reproducibility

If the tool or setting is only for your own use, but you still want to restore it across machines or after reinstallation,
move to a personal Nix configuration repository with Home Manager.

TBW

### 3. If it is personal, and reproducibility is not necessary

If you just want to try additional tools without moving to a personal config repository yet, use `nix profile`.

Install a package:

```bash
nix profile install nixpkgs#jq
```

Install multiple packages:

```bash
nix profile install nixpkgs#ripgrep nixpkgs#fd nixpkgs#bat
```

List installed profile packages:

```bash
nix profile list
```

Remove a package:

```bash
nix profile remove nixpkgs#jq
```

Upgrade installed profile packages:

```bash
nix profile upgrade --all
```
