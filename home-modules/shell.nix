{ pkgs, ... }:

{
  home.packages = [
    pkgs.bash-completion
    pkgs.colordiff
    pkgs.coreutils
  ];

  xdg.configFile = {
    "issl/shell/env.sh".source = ../assets/shell/env.sh;
    "issl/shell/rc.sh".source = ../assets/shell/rc.sh;
    "issl/shell/.dircolors".source = ../assets/shell/.dircolors;
    "issl/bash/.bash_profile".source = ../assets/bash/bash_profile.bash;
    "issl/bash/.bashrc".source = ../assets/bash/bashrc.bash;
  };
}
