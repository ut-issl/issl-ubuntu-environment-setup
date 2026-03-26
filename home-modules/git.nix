{ pkgs, ... }:

{
  home.packages = [ pkgs.git ];

  home.file.".config/issl/git/.gitconfig".source = ../assets/git/.gitconfig;
}
