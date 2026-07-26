{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  home.packages = [
    pkgs.deadnix
    pkgs.nixfmt
    pkgs.statix
  ];

  xdg.configFile."issl/nix/nix.conf".source = ../assets/nix/nix.conf;

  programs.home-manager.enable = true;
}
