{ lib, pkgs, activeProfile, ... }:

let
  virtualisationEnabled = activeProfile == "desktop";
in
{
  # kestrel (Ubuntu 26.04 LTS) should be suspended via `virsh managedsave` rather than
  # shut down. The save image requires ~16 GB of disk headroom on the host.

  virtualisation.libvirtd = {
    enable = virtualisationEnabled;
    qemu = {
      runAsRoot = false;
      swtpm.enable = true;
    };
  };

  users.users.jake.extraGroups = lib.optionals virtualisationEnabled [ "libvirtd" ];

  services.cockpit = {
    enable = virtualisationEnabled;
    port = 9090;
  };

  environment.systemPackages = lib.optionals virtualisationEnabled [
    pkgs.cockpit-machines
  ];

  networking.firewall.interfaces.br0.allowedTCPPorts = lib.optionals virtualisationEnabled [ 9090 ];
}
