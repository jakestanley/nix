# turing

nix-darwin uses `darwin-rebuild` (exported as a flake package) rather than `nixos-rebuild`.

```bash
sudo -H nix --extra-experimental-features "nix-command flakes" \
  run ".#darwin-rebuild" -- switch --flake ".#turing"
```

## Manual installation

- Wireguard (App Store)
- Guitar Pro 8 (their website)

### openconnect-sso

Doesn't build cleanly with nix, pipx, or brew. Install via macports:

```sh
sudo port install openconnect-sso
```
