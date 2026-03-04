{ lib, python3Packages, torchPackage ? python3Packages.torch, torchaudioPackage ? python3Packages.torchaudio }:

let
  rev = "fb672c9584997c2b05e148eeaa65b4c23ed4693b";
  src = builtins.fetchGit {
    url = "https://github.com/sigsep/open-unmix-pytorch.git";
    ref = "refs/heads/master";
    inherit rev;
  };
in
python3Packages.buildPythonApplication rec {
  pname = "openunmix";
  version = "1.3.0+unstable.${lib.substring 0 7 rev}";

  inherit src;
  pyproject = true;

  build-system = [
    python3Packages.setuptools
  ];

  dependencies = [
    python3Packages.numpy
    torchPackage
    torchaudioPackage
    python3Packages.tqdm
  ];

  pythonImportsCheck = [ "openunmix" "openunmix.filtering" ];

  meta = with lib; {
    description = "PyTorch-based music source separation toolkit";
    homepage = "https://github.com/sigsep/open-unmix-pytorch";
    license = licenses.mit;
    mainProgram = "umx";
    platforms = platforms.unix;
  };
}
