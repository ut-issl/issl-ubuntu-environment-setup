{ pkgs, ... }:

{
  home = {
    packages = [
      pkgs.cargo
      pkgs.cargo-about
      pkgs.rust-analyzer
      pkgs.rustc
      pkgs.rustup
    ];

    file.".config/issl/rust/config.toml".source = ../assets/rust/config.toml;
  };
}
