{ pkgs, ... }:

{
  home = {
    packages = [ pkgs.zsh ];

    file = {
      ".config/issl/zsh/.zprofile".source = ../assets/zsh/zprofile.zsh;
      ".config/issl/zsh/.zshrc".source = ../assets/zsh/zshrc.zsh;
    };
  };
}
