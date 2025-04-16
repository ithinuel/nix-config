{ stdenv, fetchFromGitHub, fetchYarnDeps, pkgs }: stdenv.mkDerivation rec {
  name = "_at_hexuhua_coc-copilot";
  packageName = "@hexuhua/coc-copilot";
  version = "0.0.22";
  src = fetchFromGitHub {
    owner = "hexh250786313";
    repo = "coc-copilot";
    rev = "0.0.22";
    sha256 = "sha256-So7InzEn2IHurC8bKEWHCwICE088FC7nC71H3FIjTe8=";
  };
  offlineCache = fetchYarnDeps {
    yarnLock = src + "/yarn.lock";
    hash = "sha256-RRPQJ1QBqNarIUXUUp4vvqKANjff1j0yjeW4Tl98yR8=";
  };
  patches = [ ./coc-copilot-reenable-autoUpdateCompletion.patch ];
  nativeBuildInputs = with pkgs; [
    yarnConfigHook
    yarnBuildHook
    yarnInstallHook
    nodejs
    husky
    nodePackages.rimraf
  ];
  meta = {
    description = "Copilot extension for coc.nvim";
    license = {
      spdxId = "Anti996";
      fullName = "Anti 996 License";
    };
    homepage = "https://github.com/hexuhua/coc-copilot/";
  };
}
