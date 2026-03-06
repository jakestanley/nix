{
  lib,
  python3Packages,
  torchPackage ? python3Packages.torch,
  torchaudioPackage ? python3Packages.torchaudio,
  openunmixPackage ? null,
  doraSearchPackage ? python3Packages.callPackage ../dora-search { inherit torchPackage; },
  juliusPackage ? python3Packages.julius,
}:

let
  rev = "b9ab48cad45976ba42b2ff17b229c071f0df9390";
  src = builtins.fetchGit {
    url = "https://github.com/adefossez/demucs.git";
    ref = "refs/heads/main";
    inherit rev;
  };
  openunmix =
    if openunmixPackage != null then
      openunmixPackage
    else
      python3Packages.buildPythonApplication rec {
        pname = "openunmix";
        version = "1.3.0+unstable.fb672c9";
        src = builtins.fetchGit {
          url = "https://github.com/sigsep/open-unmix-pytorch.git";
          ref = "refs/heads/master";
          rev = "fb672c9584997c2b05e148eeaa65b4c23ed4693b";
        };
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
      };
in
python3Packages.buildPythonApplication rec {
  pname = "demucs";
  version = "4.1.0a3+unstable.${lib.substring 0 7 rev}";

  inherit src;
  format = "setuptools";

  propagatedBuildInputs = [
    doraSearchPackage
    python3Packages.einops
    juliusPackage
    openunmix
    python3Packages.omegaconf
    python3Packages.pyyaml
    torchPackage
    torchaudioPackage
    python3Packages.tqdm
  ];

  pythonImportsCheck = [ "demucs" ];

  meta = with lib; {
    description = "Music source separation CLI";
    homepage = "https://github.com/adefossez/demucs";
    license = licenses.mit;
    mainProgram = "demucs";
    platforms = platforms.unix;
  };
}
