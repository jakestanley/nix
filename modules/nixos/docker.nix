{ ... }:

{
  virtualisation.docker.enable = false;

  users.users.jake.extraGroups = [ "docker" ];
}
