{ ... }:

{
  virtualisation.docker.enable = true;

  users.users.jake.extraGroups = [ "docker" ];
}
