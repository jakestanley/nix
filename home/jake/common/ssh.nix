{ ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "windows.shrike.stanley.arpa" = {
        hostname = "shrike.stanley.arpa";
        user = "mail";
        extraOptions = {
          HostKeyAlias = "windows.shrike.stanley.arpa";
        };
      };

      "shrike.stanley.arpa" = {
        hostname = "shrike.stanley.arpa";
        user = "jake";
        extraOptions = {
          HostKeyAlias = "shrike.stanley.arpa";
        };
      };

      "adler.stanley.arpa" = {
        hostname = "adler.stanley.arpa";
        user = "jake";
        extraOptions = {
          HostKeyAlias = "adler.stanley.arpa";
        };
      };
    };
  };
}
