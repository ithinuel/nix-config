# AGENTS.md

Guidance for AI agents working on this repository.

## Do not deploy — the user reviews and deploys

- **Never run deployment or activation commands**: no `home-manager switch`,
  `nixos-rebuild switch/boot`, `darwin-rebuild switch`, `deploy`, or anything that mutates
  the running system, profiles, or generations.
- Prepare your changes, commit if asked, and **stop for the user's review**. The user
  deploys themselves once they've reviewed the diff.
- Read-only or dry-run inspection (e.g. `git diff`, `nix eval`, `nix flake metadata`,
  `nix show-derivation`) is fine.

## Keep the Nix store lean

The Nix store on these machines is precious. Avoid frivolous or redundant builds:

- Do **not** run full builds (`nix build`, `nix flake check`, `nix run`, full
  `home-manager switch`-style evaluations that build) just to "verify" a change unless the
  user explicitly asks for it.
- Prefer cheap validation: `nix fmt`/formatters, `statix`, `deadnix`, `nix eval` of option
  values, and the pre-commit hooks already wired up via `git-hooks.nix`.
- Use `nix build --dry-run` / `nix eval` to see *what would* build without actually building.
- Reuse existing results: don't re-evaluate unchanged configurations, don't bump inputs
  casually (each `nix flake update` pulls and can build a new world).
- If a heavyweight build is genuinely necessary, say so first and let the user decide.

## SSH to remote hosts

- You may access remote hosts over SSH, but the SSH agent may not have your key loaded:
  **the first connection in a session often requires the user to connect once themselves**
  (e.g. to unlock the key via pinentry/gnome-keyring or agent forwarding).
- If authentication fails with "no identities" or a passphrase prompt you cannot answer,
  ask the user to connect to that host once, then retry.

## Host topology and where changes belong

- Only `tleilax` and `ithinuel-air` have a working copy of this repo in
  `~/.config/home-manager`. The state of that path on **any other machine is not
  relevant** — hosts like `ix` and `octoprint` are managed and deployed remotely from
  this repo's committed state.
- Therefore: always make changes in this checkout (on tleilax or ithinuel-air), never by
  editing files in place on other machines. "Fixing" a host means changing its config
  here (`hosts/linux/ix/`, etc.), not touching the machine.
