{ pkgs, ... }:

{
  home = {
    packages = [ pkgs.uv ];

    file.".config/issl/python/pythonrc.py".source = ../assets/python/pythonrc.py;
  };
}
