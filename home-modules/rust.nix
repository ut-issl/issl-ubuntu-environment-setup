{ lib, pkgs, ... }:

{
  home.packages = [
    pkgs.rustup
    pkgs.cargo-about
    pkgs.cargo-deny
    pkgs.cargo-hack
    pkgs.cargo-llvm-cov
    pkgs.cargo-nextest
    pkgs.cargo-dist
  ];

  xdg.configFile."issl/rust/config.toml".source = ../assets/rust/config.toml;

  home.activation.rustupEnsureDefaultToolchain = lib.hm.dag.entryAfter [ "installPackages" ] ''
    rustup=${pkgs.rustup}/bin/rustup
    if ! "$rustup" default >/dev/null 2>&1; then
      run "$rustup" default stable
    fi
  '';
}
