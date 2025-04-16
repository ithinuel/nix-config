{ pkgs, lib, tcl, tk }: tcl.mkTclDerivation rec {
  pname = "awthemes";
  version = "10.4.0";

  src = pkgs.fetchzip {
    url = "mirror://sourceforge/tcl-awthemes/awthemes-${version}.zip";
    hash = "sha256-eObNyKgW7KvcRoYy/xmbzkA3ymw3fkywDzoC6gjZM0s=";
  };

  buildInputs = [ tcl tk ];
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/lib
    cp -r pkgIndex.tcl $(cat pkgIndex.tcl | grep -o '\w\+.tcl' | uniq -0) i/ $out/lib
  '';

  meta = {
    homepage = "https://sourceforge.net/projects/tcl-awthemes/";
    description = "awthemes";
    licenses = with lib.licences; [ zlib libpng ];
    maintainers = with lib.maintainers; [ kovirobi fgaz ];
  };
}
