{ pkgs, lib, tcl }: tcl.mkTclDerivation {
  pname = "gdb-dashboard";
  version = "v0.17.2";

  src = pkgs.fetchFromGitHub {
    owner = "cyrus-and";
    repo = "gdb-dashboard";
    rev = "v0.17.2";
    hash = "sha256-UGHiYroUdqCr+a3ZgR1qKXQ3fiy2aQ5qo8gXefF9XDg=";
  };

  enableParallelBuilding = true;

  installPhase = ''
    mkdir -p $out
    cp .gdbinit $out
  '';

  meta = {
    homepage = "https://github.com/cyrus-and/gdb-dashboard";
    description = "gdb-dashboard";
    licenses = with lib.licences; [ mit ];
  };
}
