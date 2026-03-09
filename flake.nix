{
  description = "shrike NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/dd9b079222d43e1943b6ebd802f04fd959dc8e61";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    cherri = {
      url = "github:electrikmilk/cherri/2ca7dfea38ef852484866ad41b232584d8e62f0c";
      inputs.nixpkgs.follows = "nixpkgs";
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
        homelab-demucs = final.callPackage ./pkgs/homelab-demucs { };
        homelab-ollama = final.callPackage ./pkgs/homelab-ollama { };
        homelab-rtx = final.callPackage ./pkgs/homelab-rtx { };
        sleep-on-lan = final.callPackage ./pkgs/sleep-on-lan { };
      };

      mkTuringDarwin = dockProfile: inputs.nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = {
          inherit inputs;
          inherit dockProfile;
        };
        modules = [
          { nixpkgs.overlays = [ overlay ]; }
          ./hosts/turing/default.nix
          inputs.home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "hm-backup";
              extraSpecialArgs = {
                inherit inputs;
                hostname = "turing";
              };
              users.jake = import ./home/jake/home.nix;
            };
          }
        ];
      };
    in {
      overlays.default = overlay;

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
          inherit (pkgs) homelab-demucs homelab-ollama homelab-rtx sleep-on-lan;
        }
        // lib.optionalAttrs (lib.hasAttrByPath [ "packages" system "darwin-rebuild" ] inputs.nix-darwin) {
          darwin-rebuild = inputs.nix-darwin.packages.${system}.darwin-rebuild;
        });

      darwinConfigurations.turing = mkTuringDarwin "personal";
      darwinConfigurations.turing-personal = mkTuringDarwin "personal";
      darwinConfigurations.turing-work = mkTuringDarwin "work";

      homeConfigurations.turing = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          overlays = [ overlay ];
        };
        extraSpecialArgs = {
          hostname = "turing";
        };
        modules = [
          ./home/jake/home.nix
        ];
      };

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
