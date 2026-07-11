{ pkgs, ... }:

{
  home.packages = [
    pkgs.git
    pkgs.gh
  ];

  xdg.configFile."issl/git/.gitconfig".source = ../assets/git/.gitconfig;
}
