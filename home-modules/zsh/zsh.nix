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

      if [ ! -f "$link" ] || [ ! -x "$link" ]; then
        echo "$link is not an executable file. Run a Home Manager switch, or remove the path if it is in the way." >&2
        exit 1
      fi

      if ! grep -Fxq "$link" /etc/shells; then
        if [ -s /etc/shells ] && [ -n "$(tail -c1 /etc/shells)" ]; then
          printf '\n' >>/etc/shells
        fi
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
        "issl/zsh/.zprofile".source = ./zprofile.zsh;
        "issl/zsh/.zshrc".source = ./zshrc.zsh;
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
