{ pkgs, ... }:

{
  home = {
    packages = [
      pkgs.cargo
      pkgs.cargo-about
      pkgs.rustc
      pkgs.rustup
    ];

    file.".config/issl/rust/config.toml".source = ../assets/rust/config.toml;
  };
}
