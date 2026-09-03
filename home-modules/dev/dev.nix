{ pkgs, ... }:

{
  home.packages = [
    pkgs.commitizen
    pkgs.prek
    pkgs.typos
  ];
}
