{
  lib,
  python,
  torchPackage ? python.pkgs.torch,
  treetablePackage ? null,
}:

let
  pyPkgs = python.pkgs;
  hydraCore = pyPkgs."hydra-core";
  treetable =
    if treetablePackage != null then
      treetablePackage
    else if pyPkgs ? treetable then
      pyPkgs.treetable
    else
      pyPkgs.buildPythonPackage rec {
        pname = "treetable";
        version = "0.2.6";
        format = "setuptools";

        src = pyPkgs.fetchPypi {
          inherit pname version;
          hash = "sha256-fh1i285QP78kVhruFGG4+8wsIy/0VmHDudDCCBx5W98=";
        };
      };
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
    pyPkgs.retrying
    pyPkgs.submitit
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
