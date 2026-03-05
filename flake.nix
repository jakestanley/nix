{
  description = "shrike NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/dd9b079222d43e1943b6ebd802f04fd959dc8e61";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = inputs@{ nixpkgs, ... }:
    let
      lib = nixpkgs.lib;
      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      forAllSystems = lib.genAttrs supportedSystems;
      overlay = final: prev: {
        homelab-arcade = final.callPackage ./pkgs/homelab-arcade { };
        homelab-demucs = final.callPackage ./pkgs/homelab-demucs { };
        homelab-ollama = final.callPackage ./pkgs/homelab-ollama { };
        homelab-rtx = final.callPackage ./pkgs/homelab-rtx { };
        sleep-on-lan = final.callPackage ./pkgs/sleep-on-lan { };
      };
    in {
      overlays.default = overlay;

      nixosModules.cs2Dedicated = ./modules/nixos/cs2-dedicated.nix;
      nixosModules.homelabArcade = ./modules/nixos/homelab-arcade.nix;
      nixosModules.homelabDemucs = ./modules/nixos/homelab-demucs.nix;
      nixosModules.homelabOllama = ./modules/nixos/homelab-ollama.nix;
      nixosModules.rtx = ./modules/nixos/rtx.nix;
      nixosModules.sleepOnLan = ./modules/nixos/sleep-on-lan.nix;

      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ overlay ];
          };
        in {
          default = pkgs.homelab-rtx;
          inherit (pkgs) homelab-arcade homelab-demucs homelab-ollama homelab-rtx sleep-on-lan;
        });

      nixosConfigurations.shrike = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
        };
        modules = [
          { nixpkgs.overlays = [ overlay ]; }
          ./hosts/shrike/default.nix
        ];
      };
    };
}
