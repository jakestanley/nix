{ inputs, pkgs, lib, ... }:

{
    imports = [
        ./openvpn.nix
        ./plex.nix
        ./samba.nix
        ./tls.nix
        ./wireguard.nix
    ];
}
