{
  config,
  lib,
  pkgs,
  ...
}:

let
  loginShellLink = "${config.xdg.stateHome}/issl/login-shell";

  loginShellSetup = pkgs.writeShellApplication {
    name = "issl-login-shell-setup";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
    ];
    text = ''
      link="${loginShellLink}"
      user="${config.home.username}"

      if [ ! -e "$link" ]; then
        echo "$link does not exist. Run a Home Manager switch first." >&2
        exit 1
      fi

      if ! grep -Fxq "$link" /etc/shells; then
        printf '%s\n' "$link" >>/etc/shells
      fi

      /usr/bin/chsh -s "$link" "$user"
    '';
  };
in
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

  config = lib.mkMerge [
    {
      xdg.stateFile."issl/login-shell" = {
        source =
          if config.issl.zsh.enable then
            "${pkgs.zsh}/bin/zsh"
          else
            config.lib.file.mkOutOfStoreSymlink "/bin/bash";
        force = true;
      };
    }

    (lib.mkIf config.issl.zsh.enable {
      home.packages = [
        pkgs.zsh
        loginShellSetup
      ];

      xdg.configFile = {
        "issl/zsh/.zprofile".source = ../../assets/zsh/zprofile.zsh;
        "issl/zsh/.zshrc".source = ../../assets/zsh/zshrc.zsh;
      };

      home.activation.checkLoginShell = lib.hm.dag.entryAnywhere ''
        current_login_shell="$(${pkgs.getent}/bin/getent passwd "${config.home.username}" | cut -d: -f7 || true)"
        if [ -n "$current_login_shell" ] && [ "$current_login_shell" != "${loginShellLink}" ]; then
          warnEcho "Your login shell is $current_login_shell, which Home Manager does not manage."
          warnEcho "To hand it over so that it follows this configuration, run"
          warnEcho "  sudo ${lib.getExe loginShellSetup}"
        fi
      '';
    })
  ];
}
