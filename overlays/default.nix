_: _: super:
super.lib.recursiveUpdate
  (super.lib.packagesFromDirectoryRecursive {
    inherit (super.pkgs) callPackage;
    directory = ./pkgs;
  })
{ }
