{ activeProfile, ... }:

{
  virtualisation.docker.enable = activeProfile != "gaming";
  hardware.nvidia-container-toolkit.enable = activeProfile != "gaming";
}
