{ pkgs, ... }:

{
  home = {
    packages = [
      pkgs.cargo-about
      pkgs.rust-analyzer
      pkgs.rustup
    ];

    file.".config/issl/rust/config.toml".source = ../assets/rust/config.toml;
  };
}
