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
  boot.resumeDevice = "/dev/disk/by-label/nixos-root";

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

  # After hibernate resume, NVIDIA needs a moment to reinitialise before Sway
  # can render correctly. Cycle DPMS off/on to force the display to resync.
  powerManagement.resumeCommands = ''
    sleep 3
    sock=$(ls /run/user/1000/sway-ipc.* 2>/dev/null | head -1)
    if [ -n "$sock" ]; then
      su jake -c "SWAYSOCK=$sock XDG_RUNTIME_DIR=/run/user/1000 ${pkgs.sway}/bin/swaymsg output '*' dpms off"
      sleep 1
      su jake -c "SWAYSOCK=$sock XDG_RUNTIME_DIR=/run/user/1000 ${pkgs.sway}/bin/swaymsg output '*' dpms on"
    fi
  '';
}
