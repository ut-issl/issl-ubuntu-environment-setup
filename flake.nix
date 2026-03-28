{
  description = "Nix-based ISSL Ubuntu environment setup";

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
        {
          system,
          enableZsh ? false,
        }:
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
          extraSpecialArgs = {
            inherit enableZsh;
          };
          modules = [
            ./home-modules/common.nix
          ]
          ++ [
            {
              home = {
                inherit username homeDirectory;
                stateVersion = "25.05";
              };
            }
          ];
        };
    in
    {
      packages = forAllSystems (
        system:
        {
          default = home-manager.packages.${system}.home-manager;
          inherit (home-manager.packages.${system}) home-manager;
        }
      );

      homeConfigurations = {
        issl-common-x86_64-linux = mkHomeConfiguration {
          system = "x86_64-linux";
        };
        issl-common-aarch64-linux = mkHomeConfiguration {
          system = "aarch64-linux";
        };
        issl-common-zsh-x86_64-linux = mkHomeConfiguration {
          system = "x86_64-linux";
          enableZsh = true;
        };
        issl-common-zsh-aarch64-linux = mkHomeConfiguration {
          system = "aarch64-linux";
          enableZsh = true;
        };
      };

      formatter = forAllSystems (system: (mkPkgs system).nixfmt-rfc-style);

      checks = forAllSystems (
        system:
        {
          home = self.homeConfigurations."issl-common-${system}".activationPackage;
          home-zsh = self.homeConfigurations."issl-common-zsh-${system}".activationPackage;
        }
      );
    };
}
