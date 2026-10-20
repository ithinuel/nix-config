inputs: final: super:
let
  callPackage = final.lib.callPackageWith ({ inherit inputs; } // super);
in
super.lib.recursiveUpdate
  (super.lib.packagesFromDirectoryRecursive {
    inherit callPackage;
    directory = ./pkgs;
  })
{ }
