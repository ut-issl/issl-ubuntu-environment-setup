{ lib, ... }:

let
  entries = builtins.readDir ./.;

  strayModules = lib.attrNames (
    lib.filterAttrs (
      name: type: type != "directory" && name != "default.nix" && lib.hasSuffix ".nix" name
    ) entries
  );
in
{
  xdg.enable = true;

  imports =
    lib.throwIf (strayModules != [ ])
      "home-modules/ takes one directory per module: move ${lib.concatStringsSep ", " strayModules} to <name>/<name>.nix"
      (
        lib.mapAttrsToList (
          name: _:
          let
            module = ./. + "/${name}/${name}.nix";
          in
          if builtins.pathExists module then
            module
          else
            throw "home-modules/${name}/ must contain ${name}.nix"
        ) (lib.filterAttrs (_: type: type == "directory") entries)
      );
}
