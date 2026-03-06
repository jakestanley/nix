{
  lib,
  python3Packages,
  torchPackage ? python3Packages.torch,
  torchaudioPackage ? python3Packages.torchaudio,
  openunmixPackage ? python3Packages.openunmix,
  juliusPackage ? python3Packages.julius,
}:

let
  rev = "b9ab48cad45976ba42b2ff17b229c071f0df9390";
  src = builtins.fetchGit {
    url = "https://github.com/adefossez/demucs.git";
    ref = "refs/heads/main";
    inherit rev;
  };
in
python3Packages.buildPythonApplication rec {
  pname = "demucs";
  version = "4.1.0a3+unstable.${lib.substring 0 7 rev}";

  inherit src;
  format = "setuptools";

  propagatedBuildInputs = [
    python3Packages.einops
    juliusPackage
    openunmixPackage
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
