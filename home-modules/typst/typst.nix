{ pkgs, ... }:

{
  home.packages = [
    pkgs.typst
    pkgs.typstyle
  ];
}
