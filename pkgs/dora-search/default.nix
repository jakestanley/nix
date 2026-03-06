{
  lib,
  python3,
  torchPackage ? python3.pkgs.torch,
}:

let
  pyPkgs = python3.pkgs;
  hydraCore = pyPkgs."hydra-core";
  pytorchLightning = pyPkgs."pytorch-lightning";
in
pyPkgs.buildPythonPackage rec {
  pname = "dora-search";
  version = "0.1.12";
  pyproject = true;

  src = pyPkgs.fetchPypi {
    pname = "dora_search";
    inherit version;
    hash = "sha256-KVb9LEx+S5pIMOg/DUz5Yb5Fz7oaLwVwKB6R0VrFFvs=";
  };

  build-system = [
    pyPkgs.setuptools
  ];

  dependencies = [
    hydraCore
    pytorchLightning
    pyPkgs.retrying
    pyPkgs.submitit
    torchPackage
    pyPkgs.treetable
  ];

  pythonImportsCheck = [ "dora" "dora.log" ];

  meta = with lib; {
    description = "Experiment management framework for PyTorch";
    homepage = "https://github.com/facebookresearch/dora";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
