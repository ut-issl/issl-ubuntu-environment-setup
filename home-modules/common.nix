{ pkgs, enableZsh ? false, ... }:

{
  home.packages = [
    pkgs.git
    pkgs.uv
  ] ++ pkgs.lib.optional enableZsh pkgs.zsh;

  home.file.".config/issl/git/.gitconfig".source = ../assets/git/.gitconfig;
}
