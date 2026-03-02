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

  outputs = inputs@{ nixpkgs, ... }: {
    nixosConfigurations.shrike = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs;
      };
      modules = [
        ./hosts/shrike/default.nix
      ];
    };
  };
}
