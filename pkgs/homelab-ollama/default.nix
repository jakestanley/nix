{ lib, python3Packages }:

let
  src = builtins.fetchGit {
    url = "git@github.com:jakestanley/homelab-ollama.git";
    ref = "refs/heads/systemd";
    rev = "57757f10602cc9f911f72750516748be8d9e2110";
  };
in
python3Packages.buildPythonApplication rec {
  pname = "homelab-ollama";
  version = "0.0.0+unstable.57757f1";

  # Pinned private source fetched at build/evaluation time. This host is
  # expected to have read-only credentials for the upstream repository.
  inherit src;

  pyproject = true;

  build-system = with python3Packages; [
    setuptools
  ];

  dependencies = with python3Packages; [
    flask
    psutil
    python-dotenv
  ];

  postPatch = ''
    mkdir -p homelab_ollama/templates
    cp app.py homelab_ollama/__init__.py
    cp templates/index.html homelab_ollama/templates/index.html

    cat > pyproject.toml <<EOF
    [build-system]
    requires = ["setuptools>=68"]
    build-backend = "setuptools.build_meta"

    [project]
    name = "homelab-ollama"
    version = "${version}"
    description = "Host service wrapper for a locally installed Ollama runtime"
    requires-python = ">=3.11"

    [project.scripts]
    homelab-ollama = "homelab_ollama:main"

    [tool.setuptools]
    include-package-data = true

    [tool.setuptools.packages.find]
    include = ["homelab_ollama"]

    [tool.setuptools.package-data]
    homelab_ollama = ["templates/*.html"]
    EOF
  '';

  pythonImportsCheck = [ "homelab_ollama" ];

  meta = with lib; {
    description = "Homelab wrapper service for managing a local Ollama runtime";
    homepage = "https://github.com/jakestanley/homelab-ollama";
    mainProgram = "homelab-ollama";
    platforms = platforms.unix;
  };
}
