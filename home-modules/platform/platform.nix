{ lib, pkgs, ... }:

{
  targets.genericLinux = {
    enable = lib.mkDefault pkgs.stdenv.hostPlatform.isLinux;
    gpu.enable = lib.mkDefault false;
  };
}
