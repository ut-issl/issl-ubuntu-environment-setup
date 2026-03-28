{ pkgs, ... }:

{
  home.packages = [
    pkgs.cargo
    pkgs.cargo-about
    pkgs.rustc
    pkgs.rustup
  ];
}
