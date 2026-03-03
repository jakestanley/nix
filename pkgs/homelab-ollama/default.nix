{ lib, python3Packages }:

let
  src = builtins.fetchGit {
    url = "https://github.com/jakestanley/homelab-ollama.git";
    ref = "refs/heads/systemd";
    rev = "6aeadf9370b7ed7ff654c69b2a29aa358593d360";
  };
in
python3Packages.buildPythonApplication rec {
  pname = "homelab-ollama";
  version = "0.0.0+unstable.6aeadf9";

  # Pinned public source fetched at build/evaluation time.
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
