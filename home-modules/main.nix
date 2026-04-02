{ lib, enableZsh, ... }:

{
  xdg.enable = true;

  imports =
    [
      ./nix.nix
      ./shell.nix
      ./git.nix
      ./cpp.nix
      ./python.nix
      ./rust.nix
      ./vim.nix
    ]
    ++ lib.optional enableZsh ./zsh.nix;
}
