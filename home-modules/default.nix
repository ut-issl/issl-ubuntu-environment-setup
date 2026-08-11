{ lib, ... }:

{
  xdg.enable = true;

  imports = lib.mapAttrsToList (name: _: ./common + "/${name}") (
    lib.filterAttrs (
      name: type:
      if type == "directory" then
        builtins.pathExists (./common + "/${name}/default.nix")
      else
        lib.hasSuffix ".nix" name
    ) (builtins.readDir ./common)
  );
}
