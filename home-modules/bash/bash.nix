{ pkgs, ... }:

{
  home.packages = [ pkgs.bash-completion ];

  xdg.configFile."issl/bash/.bashrc".source = ./bashrc.bash;
}
