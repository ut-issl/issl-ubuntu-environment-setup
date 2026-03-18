{ pkgs, packageSets }:

pkgs.symlinkJoin {
  name = "issl-common";
  paths = packageSets.common;
}
