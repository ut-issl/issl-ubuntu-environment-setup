{ pkgs, ... }:

{
  home.packages = [
    pkgs.jq
    pkgs.poppler-utils
    pkgs.tree
  ];
}
