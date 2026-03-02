{ inputs, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    sharedModules = [
      inputs.plasma-manager.homeModules.plasma-manager
    ];
    users.jake = import ../../home/jake/home.nix;
  };
}
