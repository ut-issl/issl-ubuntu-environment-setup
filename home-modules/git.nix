{ pkgs, ... }:

{
  home = {
    packages = [ pkgs.git ];

    file.".config/issl/git/.gitconfig".source = ../assets/git/.gitconfig;
  };
}
