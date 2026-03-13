{ inputs, pkgs, lib, ... }:

{
    imports = [
        ./registry.nix
        ./dns.nix
        ./nginx.nix
        ./openvpn.nix
        ./plex.nix
        ./samba.nix
        ./tls.nix
    ];
}
