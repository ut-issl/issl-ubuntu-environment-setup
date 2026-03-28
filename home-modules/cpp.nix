{ pkgs, ... }:

{
  home = {
    packages = [
      pkgs.gcc_multi
      pkgs.gnumake
      pkgs.cmake
      pkgs.clang-tools
      pkgs.pkg-config
    ];

    file.".clang-format".source = ../assets/cpp/clang-format.yaml;
  };
}
