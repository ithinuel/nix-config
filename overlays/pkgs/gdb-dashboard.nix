{ lib, tcl, inputs, pkgs }: tcl.mkTclDerivation {
  pname = "gdb-dashboard";
  version = "v0.17.5";

  src = inputs.gdb-dashboard;

  enableParallelBuilding = true;

  propagatedBuildInputs = [ pkgs.python3Packages.pygments ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp .gdbinit $out

    # make pygments part of gdb's python path.
    p=$(toPythonPath ${pkgs.python3Packages.pygments})
    sed -i "/import os/a import sys; sys.path.append('$p')" $out/.gdbinit

    runHook postInstall
  '';

  meta = {
    homepage = "https://github.com/cyrus-and/gdb-dashboard";
    description = "gdb-dashboard";
    licenses = with lib.licences; [ mit ];
  };
}
