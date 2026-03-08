{ config, lib, ... }:

let
  jakeAuthorizedKeys =
    lib.attrByPath [ "users" "users" "jake" "openssh" "authorizedKeys" "keys" ] [ ] config;
in
{
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  assertions = [
    {
      assertion = jakeAuthorizedKeys != [ ];
      message = ''
        users.users.jake.openssh.authorizedKeys.keys must be set per host with at least one key.
      '';
    }
  ];
}
