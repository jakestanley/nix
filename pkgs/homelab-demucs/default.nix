{ lib, python3Packages, torchPackage ? python3Packages.torch }:

let
  src = builtins.fetchGit {
    url = "https://github.com/jakestanley/homelab-demucs.git";
    ref = "refs/heads/systemd";
    rev = "27a4f39b1be15ba53880788aad0dfedbe88271ef";
  };
in
python3Packages.buildPythonApplication rec {
  pname = "homelab-demucs";
  version = "0.0.0+unstable.27a4f39";

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
    torchPackage
  ];

  postPatch = ''
    cat > pyproject.toml <<EOF
    [build-system]
    requires = ["setuptools>=68"]
    build-backend = "setuptools.build_meta"

    [project]
    name = "homelab-demucs"
    version = "${version}"
    description = "Host-run HTTP service for Demucs separation jobs"
    requires-python = ">=3.11"

    [project.scripts]
    homelab-demucs = "demucs_service.server:main"

    [tool.setuptools.packages.find]
    include = ["demucs_service"]

    [tool.setuptools.package-data]
    demucs_service = ["static/*.html", "openapi.json"]
    EOF
  '';

  pythonImportsCheck = [ "demucs_service" ];

  meta = with lib; {
    description = "Host-run Demucs separation service";
    homepage = "https://github.com/jakestanley/homelab-demucs";
    mainProgram = "homelab-demucs";
    platforms = platforms.unix;
  };
}
