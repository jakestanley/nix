{
  description = "multi-host NixOS and nix-darwin configuration";

  inputs = {
#    nixpkgs.url = "github:NixOS/nixpkgs/dd9b079222d43e1943b6ebd802f04fd959dc8e61";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cherri = {
      url = "github:electrikmilk/cherri/2ca7dfea38ef852484866ad41b232584d8e62f0c";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    homelab-infra = {
      url = "git+ssh://git@github.com/jakestanley/homelab-infra";
      flake = false;
    };
  };

  outputs = inputs@{ nixpkgs, ... }:
    let
      lib = nixpkgs.lib;
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      forAllSystems = lib.genAttrs supportedSystems;
      overlay = final: prev: {
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

      mkLinuxHome = hostname: system: inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };
        extraSpecialArgs = {
          inherit hostname;
        };
        modules = [
          ./home/jake/home.nix
        ];
      };

      mkNixosHost = hostname: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
        };
        modules = [
          { nixpkgs.overlays = [ overlay ]; }
          (./hosts + "/${hostname}/default.nix")
        ];
      };
    in {
      overlays.default = overlay;

      nixosModules.sleepOnLan = ./hosts/shrike/base/sleep-on-lan.nix;

      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ overlay ];
          };
        in
        # sleep-on-lan is Linux-only
        lib.optionalAttrs (lib.hasSuffix "-linux" system) {
          default = pkgs.sleep-on-lan;
          inherit (pkgs) sleep-on-lan;
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
      homeConfigurations.adler = mkLinuxHome "adler" "x86_64-linux";

      nixosConfigurations = {
        shrike      = mkNixosHost "shrike";
        kestrel     = mkNixosHost "kestrel";
        adler       = mkNixosHost "adler";
      };

      checks.x86_64-linux = {
        dns = import ./tests/dns.nix { inherit pkgs; };
        nginx = import ./tests/nginx.nix { inherit pkgs; };
      };
    };
}
