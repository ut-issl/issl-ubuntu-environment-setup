{ lib, ... }:

{
  xdg.enable = true;

  imports = lib.mapAttrsToList (name: _: ./common + "/${name}") (
    lib.filterAttrs (name: type: type == "directory" || lib.hasSuffix ".nix" name) (
      builtins.readDir ./common
    )
  );
}
