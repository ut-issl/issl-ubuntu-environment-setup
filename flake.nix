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
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      mkPkgs = system: import nixpkgs { inherit system; };
      mkHomeConfiguration =
        system:
        let
          pkgs = mkPkgs system;
          username =
            let
              value = builtins.getEnv "USER";
            in
            if value != "" then value else "issl";
          homeDirectory =
            let
              value = builtins.getEnv "HOME";
            in
            if value != "" then value else "/tmp/issl-home";
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./home-modules/git.nix
            {
              home.username = username;
              home.homeDirectory = homeDirectory;
              home.stateVersion = "25.05";
            }
          ];
        };
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
          packageSets = {
            common = import ./packages/common.nix { inherit pkgs; };
          };
          issl-common = import ./profiles/issl-common.nix {
            inherit pkgs packageSets;
          };
        in
        {
          default = issl-common;
          home-manager = home-manager.packages.${system}.home-manager;
          issl-common = issl-common;
        }
      );

      homeConfigurations = {
        issl-common-x86_64-linux = mkHomeConfiguration "x86_64-linux";
        issl-common-aarch64-linux = mkHomeConfiguration "aarch64-linux";
      };

      formatter = forAllSystems (system: (mkPkgs system).nixfmt-rfc-style);

      checks = forAllSystems (
        system:
        {
          home = self.homeConfigurations."issl-common-${system}".activationPackage;
          package = self.packages.${system}.issl-common;
        }
      );
    };
}
