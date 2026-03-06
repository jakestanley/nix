{ lib, python3Packages, torchPackage ? python3Packages.torch }:

python3Packages.buildPythonPackage rec {
  pname = "dora-search";
  version = "0.1.12";
  pyproject = true;

  src = python3Packages.fetchPypi {
    pname = "dora_search";
    inherit version;
    hash = "sha256-KVb9LEx+S5pIMOg/DUz5Yb5Fz7oaLwVwKB6R0VrFFvs=";
  };

  build-system = [
    python3Packages.setuptools
  ];

  dependencies = [
    python3Packages."hydra-core"
    python3Packages."pytorch-lightning"
    python3Packages.retrying
    python3Packages.submitit
    torchPackage
    python3Packages.treetable
  ];

  pythonImportsCheck = [ "dora" "dora.log" ];

  meta = with lib; {
    description = "Experiment management framework for PyTorch";
    homepage = "https://github.com/facebookresearch/dora";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
