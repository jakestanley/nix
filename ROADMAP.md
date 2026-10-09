# Roadmap

This repo is now only used for turing (nix-darwin). Everything else in it
is dormant: the NixOS configs for shrike, kestrel and adler, adler's
home-manager config and sleep-on-lan.

1. **Remove the adler backup script.** `scripts/backup-adler.sh` moved to
   hosts-adler's `host_backup` role (a systemd timer) on 2026-10-09. Once
   the first timer run has landed in Dropbox, delete the script here and
   the crontab notes in `hosts/adler/README.md`.
2. **Move turing to a `hosts-turing` repo**, kept as a nix-darwin flake:
   - `hosts/turing/*`;
   - the home-manager config it uses: `home/jake/home.nix`, `common/*`,
     `platforms/darwin.nix`, `hosts/turing.nix`, and
     `modules/shared/editor-env.nix`;
   - inputs nixpkgs, nix-darwin, home-manager and cherri;
   - `scripts/audit-turing-apps.sh`.

   Copy `flake.lock` so the first `darwin-rebuild switch` from the new repo
   changes nothing. Drop the Linux-only parts. Undecided: whether to carry
   the git history across with `git filter-repo` (recommended) or start
   fresh. CI can only evaluate the config on Linux; applying stays manual
   on turing.
3. **Archive this repo** once turing has switched over. Disable its
   Woodpecker `flake check` pipeline at the same time.
