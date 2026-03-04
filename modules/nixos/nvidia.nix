{ config, lib, ... }:

{
  boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    open = false;
    powerManagement.enable = false;
  };

  systemd.services.nvidia-persistence-mode = {
    description = "Enable Nvidia persistence mode";
    after = [ "systemd-modules-load.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${lib.getExe' config.hardware.nvidia.package "nvidia-smi"} --persistence-mode=1";
    };
  };
}
