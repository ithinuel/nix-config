inputs: self: super:
let
  unstable = import inputs.nixpkgs_unstable { inherit (super) system; };
  # builds a vim plugin from a github repository at a given hash
  vimPluginFromGitHub = { owner, repo, rev, hash }:
    super.vimUtils.buildVimPlugin {
      pname = "${super.lib.strings.sanitizeDerivationName repo}";
      version = rev;
      src = super.fetchFromGitHub {
        inherit owner repo rev hash;
      };
    };
in
super.lib.recursiveUpdate
  (super.lib.packagesFromDirectoryRecursive {
    inherit (super.pkgs) callPackage;
    directory = ./pkgs;
  })
{
  inherit (unstable.pkgs) ruff yarnConfigHook;
  libstatgrab = super.libstatgrab.overrideAttrs (prev: { buildInputs = prev.buildInputs ++ [ super.ncurses ]; });
  vimPlugins = super.vimPlugins // {
    inherit (unstable.pkgs.vimPlugins) coc-nvim;
    coc-ruff = super.vimUtils.buildVimPlugin {
      pname = "coc-ruff";
      inherit (self.coc-ruff) version meta;
      src = "${self.coc-ruff}/lib/node_modules/@yaegassy/coc-ruff";
    };
    coc-copilot = super.vimUtils.buildVimPlugin {
      pname = "coc-copilot";
      inherit (self.coc-copilot) version meta;
      src = "${self.coc-copilot}/lib/node_modules/@hexuhua/coc-copilot";
    };

    vim-archery = vimPluginFromGitHub {
      owner = "Badacadabra";
      repo = "vim-archery";
      rev = "0084b5d1199deb5c671e0e6017e9a0224f66f236";
      hash = "sha256-z2qfEHz+CagbP5GBVzARsP1+H6LjBEna6x1L0+ynzbk";
    };
  };
  #gitFull = super.gitFull.overrideAttrs (prev: {
  #  patches = prev.patches ++ [
  #    (
  #      super.fetchpatch {
  #        name = "fix-gitk-visibility.patch";
  #        url = "https://github.com/git/git/commit/1db62e44b7ec93b6654271ef34065b31496cd02e.patch?full_index=1";
  #        hash = "sha256-ntvnrYFFsJ1Ebzc6vM9/AMFLHMS1THts73PIOG5DkQo=";
  #      }
  #    )
  #  ];
  #});
}
