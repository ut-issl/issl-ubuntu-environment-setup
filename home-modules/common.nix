{ lib, enableZsh ? false, ... }:

{
  imports = [
    ./shell.nix
    ./git.nix
    ./python.nix
  ] ++ lib.optional enableZsh ./zsh.nix;
}
