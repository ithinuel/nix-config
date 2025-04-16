{ stdenv, fetchFromGitHub, fetchYarnDeps, pkgs, lib }: stdenv.mkDerivation rec {
  name = "_at_yaegassy_coc-ruff";
  packageName = "@yaegassy/coc-ruff";
  version = "0.8.0";
  src = fetchFromGitHub {
    owner = "yaegassy";
    repo = "coc-ruff";
    rev = "v0.8.0";
    hash = "sha256-7AfzaWOFNeKA2dxAgUmQuOWIqYaXTu85V9J4UTlQmvk";
  };
  offlineCache = fetchYarnDeps {
    yarnLock = src + "/yarn.lock";
    hash = "sha256-op9RAdMWj/C+yOxtOQlldHrmTRXpQlXJTxfBFejM+Dw=";
  };
  nativeBuildInputs = with pkgs; [
    yarnConfigHook
    yarnBuildHook
    yarnInstallHook
    nodejs
  ];
  meta = {
    description = "Ruff extension for coc.nvim";
    license = lib.licenses.mit;
    homepage = "https://github.com/yaegassy/coc-ruff/";
  };
}

