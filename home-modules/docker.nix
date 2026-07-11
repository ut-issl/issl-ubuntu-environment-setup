{ pkgs, ... }:

let
  dockerCompose = pkgs.symlinkJoin {
    name = "docker-compose";
    paths = [ pkgs.docker-compose ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/docker-compose" \
        --prefix DOCKER_CLI_PLUGIN_DIRS : "${pkgs.docker-compose}/libexec/docker/cli-plugins:${pkgs.docker-buildx}/libexec/docker/cli-plugins"
    '';
  };
in
{
  home.packages = [
    pkgs.docker-client
    pkgs.docker-buildx
    dockerCompose
  ];
}
