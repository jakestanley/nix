# turing

nix-darwin uses `darwin-rebuild` (exported as a flake package) rather than `nixos-rebuild`.
Select `personal` or `work` to control the Dock profile.

```bash
# personal profile
sudo -H nix --extra-experimental-features "nix-command flakes" \
  run ".#darwin-rebuild" -- switch --flake ".#turing-personal"

# work profile
sudo -H nix --extra-experimental-features "nix-command flakes" \
  run ".#darwin-rebuild" -- switch --flake ".#turing-work"
```

> **Note:** `scripts/switch-turing-dock.sh` previously handled this with a sudoers entry
> allowing passwordless execution of that exact script path. If you restore that workflow,
> add the equivalent sudoers rule for the new command path.

## Manual installation

- Wireguard (App Store)
- Guitar Pro 8 (their website)

### openconnect-sso

Doesn't build cleanly with nix, pipx, or brew. Install via macports:

```sh
sudo port install openconnect-sso
```
