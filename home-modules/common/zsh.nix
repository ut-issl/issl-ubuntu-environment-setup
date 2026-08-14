{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.issl.zsh.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    example = false;
    description = ''
      Whether to enable the shared zsh configuration.
      Set it to `false` for a Bash-only environment;
      the shared bash configuration applies either way.
    '';
  };

  config = lib.mkIf config.issl.zsh.enable {
    home.packages = [ pkgs.zsh ];

    xdg.configFile = {
      "issl/zsh/.zprofile".source = ../../assets/zsh/zprofile.zsh;
      "issl/zsh/.zshrc".source = ../../assets/zsh/zshrc.zsh;
    };
  };
}
