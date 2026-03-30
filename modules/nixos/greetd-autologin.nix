{ lib, ... }:

let
  gamescopeSession = {
    user = "jake";
    command = "steam-gamescope";
  };
in
{
  services.displayManager.sddm.enable = lib.mkForce false;

  services.greetd = {
    enable = true;
    settings = {
      initial_session = gamescopeSession;
      default_session = gamescopeSession;
    };
  };
}
