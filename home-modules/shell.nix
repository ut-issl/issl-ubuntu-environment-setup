{ pkgs, ... }:

{
  home = {
    packages = [
      pkgs.colordiff
      pkgs.coreutils
    ];

    file = {
      ".config/issl/shell/env.sh".source = ../assets/shell/env.sh;
      ".config/issl/shell/rc.sh".source = ../assets/shell/rc.sh;
      ".config/issl/shell/.dircolors".source = ../assets/shell/.dircolors;
      ".config/issl/bash/.bash_profile".source = ../assets/bash/.bash_profile;
      ".config/issl/bash/.bashrc".source = ../assets/bash/.bashrc;
    };
  };
}
