# issl-ubuntu-environment-setup

[![License](https://img.shields.io/badge/license-MIT%20OR%20Apache--2.0-blue.svg?style=flat)](#license)
[![prek](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/j178/prek/master/docs/assets/badge-v0.json)](https://github.com/j178/prek)
[![CI](https://github.com/ut-issl/issl-ubuntu-environment-setup/actions/workflows/ci.yaml/badge.svg)](https://github.com/ut-issl/issl-ubuntu-environment-setup/actions/workflows/ci.yaml)
[![Test](https://github.com/ut-issl/issl-ubuntu-environment-setup/actions/workflows/test.yaml/badge.svg)](https://github.com/ut-issl/issl-ubuntu-environment-setup/actions/workflows/test.yaml)

A repository for distributing a reproducible and maintainable shared Ubuntu environment for ISSL.

## Quick Setup

Bootstrap the ISSL Ubuntu environment with a single command:

```bash
bash <(curl -fsSL https://github.com/ut-issl/issl-ubuntu-environment-setup/releases/latest/download/setup.sh)
```

To pin the setup to a fixed release instead of `latest`, replace `latest` with a release tag such as `v0.1.1`:

```bash
bash <(curl -fsSL https://github.com/ut-issl/issl-ubuntu-environment-setup/releases/download/v0.1.1/setup.sh)
```

To override setup variables, set them before the command. For example, to change the clone destination:

```bash
INSTALL_DIR="$HOME/.local/share/issl/custom-ubuntu-environment-setup" \
bash <(curl -fsSL https://github.com/ut-issl/issl-ubuntu-environment-setup/releases/latest/download/setup.sh)
```

## License

Licensed under either of [MIT license](LICENSE-MIT) or [Apache License, Version 2.0](LICENSE-APACHE) at your option.

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in this software
by you, as defined in the Apache-2.0 license, shall be dually licensed as above,
without any additional terms or conditions.
