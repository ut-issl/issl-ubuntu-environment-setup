{
  description = "Nix-based ISSL Ubuntu environment setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      ...
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      mkPkgs = system: import nixpkgs { inherit system; };
      requireEnv =
        name:
        let
          value = builtins.getEnv name;
        in
        if value != "" then
          value
        else
          throw "Environment variable ${name} is required. Run Home Manager with --impure.";
      mkHomeConfiguration =
        {
          system,
          username ? requireEnv "USER",
          homeDirectory ? requireEnv "HOME",
          enableZsh ? false,
        }:
        let
          pkgs = mkPkgs system;
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit enableZsh;
          };
          modules = [
            ./home-modules/main.nix
          ]
          ++ [
            {
              home = {
                inherit username homeDirectory;
                stateVersion = "26.05";
              };
            }
          ];
        };
    in
    {
      packages = forAllSystems (system: {
        default = home-manager.packages.${system}.home-manager;
        inherit (home-manager.packages.${system}) home-manager;
      });

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

      checks = forAllSystems (system: {
        home =
          (mkHomeConfiguration {
            inherit system;
            username = "issl";
            homeDirectory = "/tmp/issl-home";
          }).activationPackage;
        home-zsh =
          (mkHomeConfiguration {
            inherit system;
            username = "issl";
            homeDirectory = "/tmp/issl-home";
            enableZsh = true;
          }).activationPackage;
      });
    };
}
