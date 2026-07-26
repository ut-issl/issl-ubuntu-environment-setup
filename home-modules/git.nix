{ pkgs, ... }:

{
  home.packages = [
    pkgs.git
    pkgs.gh
    pkgs.actionlint
    pkgs.zizmor
  ];

  xdg.configFile."issl/git/.gitconfig".source = ../assets/git/.gitconfig;
}
