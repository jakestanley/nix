{
  lib,
  python3,
  buildPythonApplication,
  setuptools,
  numpy,
  tqdm,
  einops,
  omegaconf,
  pyyaml,
  torchPackage ? python3.pkgs.torch,
  torchaudioPackage ? python3.pkgs.torchaudio,
  openunmixPackage ? null,
  doraSearchPackage ? python3.pkgs.callPackage ../dora-search { inherit torchPackage; },
  juliusPackage ? python3.pkgs.julius,
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
      buildPythonApplication rec {
        pname = "openunmix";
        version = "1.3.0+unstable.fb672c9";
        src = builtins.fetchGit {
          url = "https://github.com/sigsep/open-unmix-pytorch.git";
          ref = "refs/heads/master";
          rev = "fb672c9584997c2b05e148eeaa65b4c23ed4693b";
        };
        pyproject = true;

        build-system = [
          setuptools
        ];

        dependencies = [
          numpy
          torchPackage
          torchaudioPackage
          tqdm
        ];
      };
in
buildPythonApplication rec {
  pname = "demucs";
  version = "4.1.0a3+unstable.${lib.substring 0 7 rev}";

  inherit src;
  format = "setuptools";

  propagatedBuildInputs = [
    doraSearchPackage
    einops
    juliusPackage
    openunmix
    omegaconf
    pyyaml
    torchPackage
    torchaudioPackage
    tqdm
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
