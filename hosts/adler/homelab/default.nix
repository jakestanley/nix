{ inputs, pkgs, lib, ... }:

{
    imports = [
        ./registry.nix
        ./dns.nix
        ./nginx.nix
        ./tls.nix
    ];
}
