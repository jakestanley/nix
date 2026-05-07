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

  # Bridge br0 over the physical ethernet so VMs can get LAN IPs directly.
  # NM is told to leave enp4s0 and br0 alone; NixOS networking scripts bring
  # up the bridge and acquire a DHCP lease on br0. Connectivity drops briefly
  # on first apply but resumes once br0 gets its lease.
  networking.bridges = lib.mkIf enabled {
    br0.interfaces = [ "enp4s0" ];
  };
  # NM is disabled for these interfaces to avoid conflicting with the bridge.
  # dhcpcd is re-enabled and restricted to br0 so it can acquire a lease;
  # NM's default dhcpcd suppression only applies to NM-managed interfaces.
  networking.networkmanager.unmanaged =
    lib.optionals enabled [ "interface-name:enp4s0" "interface-name:br0" ];
  networking.dhcpcd.enable = lib.mkIf enabled true;
  networking.dhcpcd.allowInterfaces = lib.optionals enabled [ "br0" ];
}
