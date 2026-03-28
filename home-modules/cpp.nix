{ pkgs, ... }:

{
  home.packages = [
    pkgs.gcc_multi
    pkgs.gnumake
    pkgs.cmake
    pkgs.clang-tools
  ];
}
