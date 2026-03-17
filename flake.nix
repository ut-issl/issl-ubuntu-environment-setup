{
  description = "Nix-based ISSL Ubuntu environment setup";

  nixConfig = {
    extra-experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      mkPkgs = system: import nixpkgs { inherit system; };
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
          issl-common = pkgs.symlinkJoin {
            name = "issl-common";
            paths = [
              pkgs.git
            ];
          };
        in
        {
          default = issl-common;
          issl-common = issl-common;
        }
      );

      formatter = forAllSystems (system: (mkPkgs system).nixfmt-rfc-style);

      checks = forAllSystems (
        system:
        {
          package = self.packages.${system}.issl-common;
        }
      );
    };
}
