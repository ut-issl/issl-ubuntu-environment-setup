{ lib, ... }:

{
  xdg.enable = true;

  imports = lib.mapAttrsToList (
    name: _:
    let
      module = ./. + "/${name}/${name}.nix";
    in
    if builtins.pathExists module then
      module
    else
      throw "home-modules/${name}/ must contain ${name}.nix"
  ) (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./.));
}
