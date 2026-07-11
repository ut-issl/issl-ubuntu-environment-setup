{ pkgs, ... }:

{
  home.packages = [
    pkgs.docker-client
    pkgs.docker-compose
    pkgs.docker-buildx
  ];
}
