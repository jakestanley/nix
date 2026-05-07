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

  environment.systemPackages =
    lib.optionals enabled [ pkgs.virt-manager ];

  services.cockpit = {
    enable = enabled;
    openFirewall = enabled;
    port = 9090;
    plugins = lib.optionals enabled [ pkgs.cockpit-machines ];
    settings.WebService.Origins = lib.mkForce "https://shrike.stanley.arpa:9090 https://shrike:9090 https://cockpit.stanley.arpa";
  };

  systemd.services.libvirt-default-network = lib.mkIf enabled {
    description = "Define and autostart libvirt default NAT network";
    after = [ "libvirtd.service" ];
    requires = [ "libvirtd.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script =
      let
        networkXml = pkgs.writeText "libvirt-default-network.xml" ''
          <network>
            <name>default</name>
            <bridge name="virbr0"/>
            <forward/>
            <ip address="192.168.122.1" netmask="255.255.255.0">
              <dhcp>
                <range start="192.168.122.2" end="192.168.122.254"/>
              </dhcp>
            </ip>
          </network>
        '';
        virsh = "${pkgs.libvirt}/bin/virsh";
      in
      ''
        if ! ${virsh} net-info default &>/dev/null; then
          ${virsh} net-define ${networkXml}
        fi
        ${virsh} net-autostart default
        if ! ${virsh} net-info default | grep -q "Active:.*yes"; then
          ${virsh} net-start default
        fi
      '';
  };

}
