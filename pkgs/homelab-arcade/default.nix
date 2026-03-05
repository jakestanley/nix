{ lib, python3Packages }:

let
  rev = "f937e905b13695300a2d0affc1a8a233758f2136";
  src = builtins.fetchGit {
    url = "https://github.com/jakestanley/homelab-arcade.git";
    ref = "refs/heads/systemd";
    inherit rev;
  };
  rconPkg = python3Packages.rcon or (python3Packages.callPackage ../rcon { });
  runtimeDeps = [
    python3Packages.flask
    python3Packages.pyyaml
    rconPkg
  ];
in
python3Packages.buildPythonApplication rec {
  pname = "homelab-arcade";
  version = "0.1.0+unstable.${lib.substring 0 7 rev}";

  inherit src;
  pyproject = true;
  patches = [ ./cs2-exec-wrapper.patch ];

  build-system = [
    python3Packages.setuptools
  ];

  propagatedBuildInputs = runtimeDeps;
  pythonPath = runtimeDeps;

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail 'version = "0.1.0"' 'version = "${version}"'
  '';

  pythonImportsCheck = [
    "supervisor"
    "portal_server"
    "cs2.server"
    "sandstorm.server"
  ];

  meta = with lib; {
    description = "Web supervisor and controller for homelab game servers";
    homepage = "https://github.com/jakestanley/homelab-arcade";
    mainProgram = "homelab-arcade";
    platforms = platforms.unix;
  };
}
