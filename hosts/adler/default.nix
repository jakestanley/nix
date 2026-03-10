{ ... }:

let 
  publicKeys = (import ../../modules/nixos/public-keys.nix {}).publicKeys;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/base.nix
    ../../modules/nixos/docker.nix
    ../../modules/nixos/home-manager.nix
    ../../modules/nixos/ssh.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # create zfs mount points
  systemd.tmpfiles.rules = [
    "d /var/media   0755 root root -"
    "d /var/archive 0755 root root -"
  ];

  # Hardware config mounts ZFS datasets (data/media, data/archive). Import the pool at boot.
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.extraPools = [ "data" ];

  # increase zfs mount timeout
  systemd.services.zfs-import-data.serviceConfig.TimeoutSec = "300";

  networking.hostName = "adler";
  networking.hostId = "2a0f5297";

  users.users.jake.openssh.authorizedKeys.keys = [
    publicKeys.turing
  ];

  home-manager.extraSpecialArgs = {
    hostname = "adler";
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  services.samba = {
    enable = true;
    openFirewall = true;
    nmbd.enable = true;
    winbindd.enable = true;

    # Direct migration of live /etc/samba/smb.conf from adler.
    settings = {
      global = {
        "unix extensions" = "no";
        "server min protocol" = "SMB2";
        "client min protocol" = "SMB2";
        "server max protocol" = "SMB3";
        "client max protocol" = "SMB3";
        "server signing" = "disabled";
        "client signing" = "disabled";
        "min protocol" = "SMB2";
        "max protocol" = "SMB3";
        "ea support" = "no";
        "vfs objects" = "";
        "workgroup" = "WORKGROUP";
        "log file" = "/var/log/samba/log.%m";
        "max log size" = 1000;
        "logging" = "file";
        "panic action" = "/usr/share/samba/panic-action %d";
        "server role" = "standalone server";
        "obey pam restrictions" = "yes";
        "unix password sync" = "yes";
        "passwd program" = "/usr/bin/passwd %u";
        "passwd chat" = "*Enter\\snew\\s*\\spassword:* %n\\n *Retype\\snew\\s*\\spassword:* %n\\n *password\\supdated\\ssuccessfully* .";
        "pam password change" = "yes";
        "map to guest" = "bad user";
        "usershare allow guests" = "yes";
      };

      Books = {
        "path" = "/var/media/Books";
        "read only" = "yes";
        "write list" = "jake";
        "browseable" = "yes";
      };

      Downloads = {
        "path" = "/var/media/Downloads";
        "read only" = "yes";
        "write list" = "jake";
        "browseable" = "yes";
      };

      Games = {
        "path" = "/var/media/Games";
        "read only" = "yes";
        "write list" = "jake";
        "browseable" = "yes";
      };

      Movies = {
        "path" = "/var/media/Movies";
        "read only" = "yes";
        "write list" = "jake";
        "browseable" = "yes";
      };

      "Movies (Rare)" = {
        "path" = "/var/media/Movies (Rare)";
        "read only" = "yes";
        "write list" = "jake";
        "browseable" = "yes";
      };

      Music = {
        "path" = "/var/media/Music";
        "read only" = "yes";
        "write list" = "jake";
        "browseable" = "yes";
      };

      "Operating Systems" = {
        "path" = "/var/media/Operating Systems";
        "read only" = "yes";
        "write list" = "jake";
        "browseable" = "yes";
      };

      Other = {
        "path" = "/var/media/Other";
        "read only" = "yes";
        "write list" = "jake";
        "browseable" = "yes";
      };

      PC = {
        "path" = "/var/media/PC";
        "read only" = "yes";
        "write list" = "jake";
        "browseable" = "yes";
      };

      ROMs = {
        "path" = "/var/media/ROMs";
        "read only" = "yes";
        "write list" = "jake";
        "browseable" = "yes";
      };

      Software = {
        "path" = "/var/media/Software";
        "read only" = "yes";
        "write list" = "jake";
        "browseable" = "yes";
      };

      "Steam Deck" = {
        "path" = "/var/media/Steam Deck";
        "read only" = "yes";
        "write list" = "jake";
        "browseable" = "yes";
      };

      TV = {
        "path" = "/var/media/TV";
        "read only" = "yes";
        "write list" = "jake";
        "browseable" = "yes";
      };

      "TV (Rare)" = {
        "path" = "/var/media/TV (Rare)";
        "read only" = "yes";
        "write list" = "jake";
        "browseable" = "yes";
      };

      homes = {
        "comment" = "Home Directories";
        "browseable" = "no";
        "valid users" = "%S";
        "writable" = "yes";
      };

      printers = {
        "comment" = "All Printers";
        "browseable" = "no";
        "path" = "/var/spool/samba";
        "printable" = "yes";
        "guest ok" = "no";
        "read only" = "yes";
        "create mask" = "0700";
      };

      "print$" = {
        "comment" = "Printer Drivers";
        "path" = "/var/lib/samba/printers";
        "browseable" = "yes";
        "read only" = "yes";
        "guest ok" = "no";
      };
    };
  };

  system.stateVersion = "26.05";
}
