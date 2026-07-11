{ lib, enableZsh, ... }:

{
  xdg.enable = true;

  imports = [
    ./nix.nix
    ./shell.nix
    ./git.nix
    ./dev.nix
    ./cpp.nix
    ./node.nix
    ./python.nix
    ./rust.nix
    ./vim.nix
  ]
  ++ lib.optional enableZsh ./zsh.nix;
}
