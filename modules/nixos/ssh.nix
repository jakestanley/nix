{ ... }:

{
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  users.users.jake.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL0q1CwSf4NG0jPtBtWabETld24LR2QsIB4XQLpukXSK jake@Jacobs-MacBook-Pro.local"
  ];
}
