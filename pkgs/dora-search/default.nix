{
  lib,
  python3,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  retrying,
  submitit,
  treetable,
  torchPackage ? python3.pkgs.torch,
}:

let
  hydraCore = python3.pkgs."hydra-core";
  pytorchLightning = python3.pkgs."pytorch-lightning";
in
buildPythonPackage rec {
  pname = "dora-search";
  version = "0.1.12";
  pyproject = true;

  src = fetchPypi {
    pname = "dora_search";
    inherit version;
    hash = "sha256-KVb9LEx+S5pIMOg/DUz5Yb5Fz7oaLwVwKB6R0VrFFvs=";
  };

  build-system = [
    setuptools
  ];

  dependencies = [
    hydraCore
    pytorchLightning
    retrying
    submitit
    torchPackage
    treetable
  ];

  pythonImportsCheck = [ "dora" "dora.log" ];

  meta = with lib; {
    description = "Experiment management framework for PyTorch";
    homepage = "https://github.com/facebookresearch/dora";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
