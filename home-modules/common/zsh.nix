{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.issl.zsh.enable = lib.mkEnableOption "the shared zsh configuration";

  config = lib.mkIf config.issl.zsh.enable {
    home.packages = [ pkgs.zsh ];

    xdg.configFile = {
      "issl/zsh/.zprofile".source = ../../assets/zsh/zprofile.zsh;
      "issl/zsh/.zshrc".source = ../../assets/zsh/zshrc.zsh;
    };
  };
}
