{ buildGoModule, lib }:

let
  rev = "19c86d5eece722ed6d6c17ef825349dfb67cbec9";
  src = builtins.fetchGit {
    url = "https://github.com/SR-G/sleep-on-lan.git";
    ref = "refs/heads/master";
    inherit rev;
  };
in
buildGoModule rec {
  pname = "sleep-on-lan";
  version = "1.1.2+unstable.${lib.substring 0 7 rev}";

  inherit src;
  modRoot = "src";
  subPackages = [ "." ];

  vendorHash = "sha256-JkyxqGyZXD6cSGAVAbcS5NSw0JiLTdhTmQKYfYkH+h0=";

  ldflags = [
    "-s"
    "-w"
    "-X=main.BuildCommit=${rev}"
    "-X=main.BuildVersion=1.1.2"
    "-X=main.BuildVersionLabel=SNAPSHOT"
  ];

  doCheck = false;

  meta = with lib; {
    description = "Daemon that triggers system sleep from reversed wake-on-LAN packets";
    homepage = "https://github.com/SR-G/sleep-on-lan";
    license = licenses.asl20;
    mainProgram = "sleep-on-lan";
    platforms = platforms.linux;
  };
}
