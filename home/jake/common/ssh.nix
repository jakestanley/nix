{ ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "windows.shrike.stanley.arpa" = {
        HostName = "shrike.stanley.arpa";
        User = "mail";
        HostKeyAlias = "windows.shrike.stanley.arpa";
      };

      "shrike.stanley.arpa" = {
        HostName = "shrike.stanley.arpa";
        User = "jake";
        HostKeyAlias = "shrike.stanley.arpa";
      };

      "adler.stanley.arpa" = {
        HostName = "adler.stanley.arpa";
        User = "jake";
        HostKeyAlias = "adler.stanley.arpa";
      };
    };
  };
}
