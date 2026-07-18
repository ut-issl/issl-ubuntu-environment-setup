{ pkgs, ... }:

let
  pluginDirs = "${pkgs.docker-compose}/libexec/docker/cli-plugins:${pkgs.docker-buildx}/libexec/docker/cli-plugins";

  dockerClient = pkgs.symlinkJoin {
    name = "docker-client";
    paths = [ pkgs.docker-client ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/docker" --prefix DOCKER_CLI_PLUGIN_DIRS : "${pluginDirs}"
    '';
  };

  dockerCompose = pkgs.symlinkJoin {
    name = "docker-compose";
    paths = [ pkgs.docker-compose ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/docker-compose" --prefix DOCKER_CLI_PLUGIN_DIRS : "${pluginDirs}"
    '';
  };
in
{
  home.packages = [
    dockerClient
    dockerCompose
    pkgs.docker-buildx
  ];
}
