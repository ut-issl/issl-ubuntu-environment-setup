{ pkgs, ... }:

{
  home = {
    packages = [
      pkgs.cargo-about
      pkgs.rustup
    ];

    file.".config/issl/rust/config.toml".source = ../assets/rust/config.toml;
  };
}
