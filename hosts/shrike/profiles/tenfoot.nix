{ lib, ... }:

{
  services.displayManager.sddm.enable = lib.mkForce false;

  services.greetd = {
    enable = lib.mkForce true;
    settings = lib.mkForce {
      initial_session = { user = "jake"; command = "steam-gamescope"; };
      default_session = { user = "jake"; command = "steam-gamescope"; };
    };
  };
}
