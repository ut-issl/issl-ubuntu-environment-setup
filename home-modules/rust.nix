{ lib, pkgs, ... }:

{
  home.packages = [
    pkgs.cargo-about
    pkgs.rustup
  ];

  xdg.configFile."issl/rust/config.toml".source = ../assets/rust/config.toml;

  home.activation.rustupDefaultStable = lib.hm.dag.entryAfter [ "installPackages" ] ''
    rustup=${pkgs.rustup}/bin/rustup
    if ! "$rustup" show active-toolchain >/dev/null 2>&1; then
      run "$rustup" toolchain install stable
    fi
    if ! "$rustup" show active-toolchain 2>/dev/null | grep -Eq '^stable(-|$)'; then
      run "$rustup" default stable
    fi
  '';
}
