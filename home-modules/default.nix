{ lib, ... }:

{
  xdg.enable = true;

  imports = lib.mapAttrsToList (name: _: ./common + "/${name}") (builtins.readDir ./common);
}
