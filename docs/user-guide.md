# User Guide

## How to Use

This repository provides two ways of use:

1. Create and maintain a personal Nix/Home Manager config repository
   that is designed to import this ISSL config from the start.
   - Recommended for individual users who want customization with reproducibility and long-term maintainability.
   - See [User Guide (personal config repository)](user-guide-personal-nix-config.md).

2. Run `setup.sh` from this repository.
   - Recommended for shared PCs or users who do not need reproducible personal customization.
   - This approach assumes the shared setup is mostly sufficient, and extra tool installation is occasional.
   - See [User Guide (setup.sh workflow)](user-guide-setup-sh.md).
