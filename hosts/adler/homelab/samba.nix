{ ... }:

{
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

      # To hide directories from the guest samba share, ensure you apply the following:
      #   sudo chown jake:jake  /var/media/directory-to-hide
      #   sudo chmod 750        /var/media/directory-to-hide
      media = {
        "path" = "/var/media";
        "read only" = "no";
        "guest ok" = "yes";
        "browseable" = "yes";
        "hide unreadable" = "yes";
      }

      "print$" = {
        "comment" = "Printer Drivers";
        "path" = "/var/lib/samba/printers";
        "browseable" = "yes";
        "read only" = "yes";
        "guest ok" = "no";
      };
    };
  };
}