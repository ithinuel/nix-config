{ lib }:
let
  gitAliases = {
    g = "";
    ga = "add";
    gb = "branch";
    gbD = "branch --delete --force";
    gba = "branch --all";
    gbd = "branch --delete";
    gbm = "branch --move";
    gbs = "bisect";
    gbsb = "bisect bad";
    gbsg = "bisect good";
    gbsr = "bisect reset";
    gbss = "bisect start";
    gbvv = "branch -vv";
    gc = "commit --verbose";
    gcb = "checkout -b";
    gcl = "clone --recurse-submodules";
    gco = "checkout";
    gcp = "cherry-pick";
    gd = "diff";
    gdt = "difftool -y";
    gf = "fetch";
    gfa = "fetch --all --recurse-submodules --prune";
    gl = "pull";
    glog = "log --oneline --decorate --graph";
    gloga = "log --oneline --decorate --graph --all";
    gp = "push";
    gr = "remote";
    gra = "remote add";
    grb = "rebase";
    grba = "rebase --abort";
    grbc = "rebase --continue";
    grbi = "rebase --interactive";
    grbm = "rebase $(git_main_branch)";
    grhh = "reset --hard";
    grm = "rm";
    grv = "remote --verbose";
    gs = "submodule";
    gst = "status";
    gsta = "stash push --keep-index";
    gstc = "stash clear";
    gsti = "status --ignored";
    gstl = "stash list";
    gstp = "stash pop";
    gstu = "stash push --include-untracked";
    gts = "tag --sign";
  };

  mkGit = lib.mapAttrs (_: v: if v == "" then "git" else "git ${v}");
in
{
  cat = "bat -p";
  du = "dust --reverse";
  fd = "fd -H";
  gg = "lazygit";
  gk = "gitk --all --branches --word-diff";
  gpristine = "git reset --hard && git clean --force -dfx -e .direnv -e .pre-commit-config.yaml";
  gunwip = "git rev-list --max-count=1 --format='%s' HEAD | grep -q '--wip--' && git reset HEAD~1";
  gwip = "git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign --message '--wip-- [skip ci]'";
  hm = "home-manager";
  hme = "home-manager edit";
  hms = "home-manager switch";
  lg = "lazygit";
} // mkGit gitAliases
