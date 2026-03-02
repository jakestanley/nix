{ lib, python3Packages }:

python3Packages.buildPythonApplication rec {
  pname = "homelab-rtx";
  version = "unstable-2b93f57";

  # Vendored from upstream:
  # git@github.com:jakestanley/homelab-rtx.git
  # branch: feature/systemd
  # rev: 2b93f57e0c886ddf48799abd59d6ed110c526e87
  src = ./src;

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
