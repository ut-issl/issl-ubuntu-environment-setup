{ lib, enableZsh, ... }:

{
  xdg.enable = true;

  imports =
    [
      ./shell.nix
      ./vim.nix
      ./git.nix
      ./cpp.nix
      ./python.nix
      ./rust.nix
    ]
    ++ lib.optional enableZsh ./zsh.nix;
}
