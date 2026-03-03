{ lib, python3Packages }:

let
  src = builtins.fetchGit {
    url = "https://github.com/jakestanley/homelab-rtx.git";
    ref = "refs/heads/main";
    rev = "2104149071b60aa3399e6ef4b1d117eb502409c7";
  };
in
python3Packages.buildPythonApplication rec {
  pname = "homelab-rtx";
  # Setuptools validates project.version as PEP 440, so keep this compliant.
  version = "0.0.0+unstable.2104149";

  # Pinned public source fetched at build/evaluation time.
  inherit src;

  pyproject = true;

  build-system = with python3Packages; [
    setuptools
  ];

  dependencies = with python3Packages; [
    flask
    python-dotenv
    waitress
  ];

  postPatch = ''
    cat > pyproject.toml <<EOF
    [build-system]
    requires = ["setuptools>=68"]
    build-backend = "setuptools.build_meta"

    [project]
    name = "homelab-rtx"
    version = "${version}"
    description = "Host-run NVIDIA GPU telemetry service"
    requires-python = ">=3.11"

    [project.scripts]
    homelab-rtx = "app:main"

    [tool.setuptools]
    py-modules = ["app"]
    EOF
  '';

  pythonImportsCheck = [ "app" ];

  meta = with lib; {
    description = "NVIDIA GPU telemetry service for homelab hosts";
    homepage = "https://github.com/jakestanley/homelab-rtx";
    mainProgram = "homelab-rtx";
    platforms = platforms.unix;
  };
}
