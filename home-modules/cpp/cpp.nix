{ pkgs, ... }:

{
  home = {
    packages = [
      (if pkgs.stdenv.hostPlatform.isx86_64 then pkgs.gcc_multi else pkgs.gcc)
      pkgs.gnumake
      pkgs.cmake
      pkgs.clang-tools
      pkgs.pkg-config
    ];

    file.".clang-format".source = ./clang-format.yaml;
  };
}
