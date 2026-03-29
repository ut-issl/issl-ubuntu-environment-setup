{ pkgs, ... }:

{
  home.packages = [ pkgs.zsh ];

  xdg.configFile = {
    "issl/zsh/.zprofile".source = ../assets/zsh/zprofile.zsh;
    "issl/zsh/.zshrc".source = ../assets/zsh/zshrc.zsh;
  };
}
