{ pkgs, ... }:

{
  home.packages = [
    pkgs.git
    pkgs.uv
  ];
}
