{ pkgs, lib, activeProfile, ... }:

let
  enabled = activeProfile == "desktop";
in
{
  virtualisation.libvirtd = {
    enable = enabled;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = false;
      swtpm.enable = true;
    };
  };

  users.users.jake.extraGroups =
    lib.optionals enabled [ "libvirtd" ];

  services.cockpit = {
    enable = enabled;
    openFirewall = enabled;
    port = 9090;
  };

}
