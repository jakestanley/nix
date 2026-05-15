{ ... }:

{
  virtualisation.docker.enable = true;
  hardware.nvidia-container-toolkit.enable = true;
  users.users.jake.extraGroups = [ "docker" ];
}
