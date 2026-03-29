{ pkgs, ... }:

{
  home.packages = [ pkgs.uv ];

  xdg.configFile."issl/python/pythonrc.py".source = ../assets/python/pythonrc.py;
}
