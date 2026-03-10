{ config, lib, ... }:

{
  boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];

  services.xserver.videoDrivers = [ "nvidia" ];

  # Ensure both native and Steam (32-bit) Vulkan ICDs come from the NVIDIA
  # userspace stack under /run/opengl-driver{,-32}.
  hardware.graphics = {
    enable = true;
    extraPackages = [ config.hardware.nvidia.package ];
    extraPackages32 = [ config.hardware.nvidia.package.lib32 ];
  };

  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    open = false;
    powerManagement.enable = true;
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
