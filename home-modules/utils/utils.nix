{ pkgs, ... }:

{
  home.packages = [
    pkgs.fd
    pkgs.jq
    pkgs.poppler-utils
    pkgs.ripgrep
    pkgs.tree
  ];
}
