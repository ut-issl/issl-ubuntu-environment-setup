# issl-ubuntu-environment-setup

[![License](https://img.shields.io/badge/license-MIT%20OR%20Apache--2.0-blue.svg?style=flat)](#license)
[![prek](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/j178/prek/master/docs/assets/badge-v0.json)](https://github.com/j178/prek)
[![CI](https://github.com/ut-issl/issl-ubuntu-environment-setup/actions/workflows/ci.yaml/badge.svg)](https://github.com/ut-issl/issl-ubuntu-environment-setup/actions/workflows/ci.yaml)
[![Test](https://github.com/ut-issl/issl-ubuntu-environment-setup/actions/workflows/test.yaml/badge.svg)](https://github.com/ut-issl/issl-ubuntu-environment-setup/actions/workflows/test.yaml)

A repository for distributing a reproducible and maintainable shared Ubuntu environment for ISSL.

> [!WARNING]
> This repository is an early-stage prototype and is under active development.
> It may be made private or deleted without prior notice.
> It is provided as-is, without user support or compatibility guarantees.
> Use it at your own risk.

## How to Use

This repository provides two ways of use:

1. Create and maintain a personal Nix/Home Manager config repository
   that is designed to import this ISSL config from the start.
   - See [User Guide (personal config repository)](docs/user-guide-personal-nix-config.md).

2. Run `setup.sh` from this repository.
   - See [User Guide (setup.sh workflow)](docs/user-guide-setup-sh.md).

For more details, see the [User Guide](docs/user-guide.md).

## Documentation

- Users: see [User Guide](docs/user-guide.md).
- Developers: see [Developer Guide](docs/developer-guide.md).

## License

Licensed under either of [MIT license](LICENSE-MIT) or [Apache License, Version 2.0](LICENSE-APACHE) at your option.

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in this software
by you, as defined in the Apache-2.0 license, shall be dually licensed as above,
without any additional terms or conditions.
