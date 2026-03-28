{ pkgs, ... }:

{
  home.packages = [
    pkgs.cargo
    pkgs.rustc
    pkgs.rustup
  ];
}
