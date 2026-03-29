{ pkgs, ... }:

{
  home.packages = [
    pkgs.cargo-about
    pkgs.rustup
  ];

  xdg.configFile."issl/rust/config.toml".source = ../assets/rust/config.toml;
}
