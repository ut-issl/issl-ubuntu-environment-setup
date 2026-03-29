{ pkgs, ... }:

{
  home.packages = [ pkgs.git ];

  xdg.configFile."issl/git/.gitconfig".source = ../assets/git/.gitconfig;
}
