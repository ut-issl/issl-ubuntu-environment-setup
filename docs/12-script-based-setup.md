# Script-Based Setup

This guide covers the quick-setup workflow using `setup.sh` from this repository.

## Initial Setup

Run:

```bash
bash <(curl -fsSL https://github.com/ut-issl/issl-ubuntu-environment-setup/releases/latest/download/setup.sh)
```

To pin setup to a fixed release, replace `latest` with a tag such as `v0.1.2`:

```bash
bash <(curl -fsSL https://github.com/ut-issl/issl-ubuntu-environment-setup/releases/download/v0.1.2/setup.sh)
```

To override setup variables, set them before running the command. For example:

```bash
INSTALL_DIR="$HOME/.issl-ubuntu-environment-setup" \
bash <(curl -fsSL https://github.com/ut-issl/issl-ubuntu-environment-setup/releases/latest/download/setup.sh)
```

After setup, open a new shell.

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
