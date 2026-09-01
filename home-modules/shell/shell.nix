{ pkgs, ... }:

{
  home.packages = [
    pkgs.colordiff
    pkgs.coreutils
    pkgs.shellcheck
    pkgs.shfmt
  ];

  xdg.configFile = {
    "issl/shell/env.sh".source = ./env.sh;
    "issl/shell/rc.sh".source = ./rc.sh;
    "issl/shell/.dircolors".source = ./dircolors;
  };
}
