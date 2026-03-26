{ pkgs, ... }:

{
  home.packages = [
    pkgs.git
    pkgs.uv
  ];

  home.file.".config/issl/git/.gitconfig".source = ../assets/git/.gitconfig;
}
