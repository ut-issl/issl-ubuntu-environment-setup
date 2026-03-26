{ pkgs, ... }:

{
  home = {
    packages = [ pkgs.zsh ];
    file = {
      ".config/issl/zsh/.zprofile".source = ../assets/zsh/.zprofile;
      ".config/issl/zsh/.zshrc".source = ../assets/zsh/.zshrc;
    };
  };
}
