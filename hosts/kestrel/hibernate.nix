{ pkgs, ... }:

{
  # 32GB swap file on the root volume for hibernate.
  # Size matches RAM — must be >= physical RAM for hibernate to succeed.
  swapDevices = [{
    device = "/var/swap/hibernate";
    size = 32768;
  }];

  # Create the directory for the swap file before systemd tries to activate it.
  # tmpfiles runs too late; activation scripts run before any systemd services.
  system.activationScripts.createSwapDir = "mkdir -p /var/swap";

  # Root partition containing the swap file.
  boot.resumeDevice = "/dev/disk/by-uuid/30518ca7-a203-49cb-9a34-66f31c5f04c4";

  # resume_offset: physical block offset of the swap file within the partition.
  # This cannot be determined until the swap file exists on disk.
  #
  # After first deploy, SSH into kestrel and run:
  #   sudo filefrag -v /var/swap/hibernate | awk 'NR==4{print $4}' | tr -d '.'
  # Set the output value below and redeploy.
  #
  # TODO: set resume_offset after first deploy
  boot.kernelParams = [ "resume_offset=106496" ];

  # Suspend to RAM first; hibernate after 30 minutes of inactivity.
  systemd.sleep.settings.Sleep = {
    HibernateDelaySec = "30m";
    SuspendEstimationSec = "30m";
  };

  powerManagement.enable = true;

  # Lock the screen before suspend or hibernate so the session is protected on wake.
  systemd.services.swaylock-on-sleep = {
    description = "Lock Sway screen before sleep or hibernate";
    before = [ "sleep.target" "suspend.target" "hibernate.target" ];
    wantedBy = [ "sleep.target" "suspend.target" "hibernate.target" ];
    environment = {
      XDG_RUNTIME_DIR = "/run/user/1000";
      WAYLAND_DISPLAY = "wayland-1";
    };
    serviceConfig = {
      Type = "forking";
      User = "jake";
      ExecStart = "${pkgs.swaylock}/bin/swaylock -c 000000";
    };
  };
}
