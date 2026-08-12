{ pkgs, ... }:

{
  home.packages = [
    pkgs.git
    pkgs.gh
    pkgs.act
    pkgs.actionlint
    pkgs.zizmor
  ];

  xdg.configFile."issl/git/.gitconfig".source = ../../assets/git/.gitconfig;
}
