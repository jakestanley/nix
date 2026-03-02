{
  description = "shrike NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/dd9b079222d43e1943b6ebd802f04fd959dc8e61";
  };

  outputs = { nixpkgs, ... }: {
    nixosConfigurations.shrike = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
      ];
    };
  };
}
