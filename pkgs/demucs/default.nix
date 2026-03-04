{ lib, python3Packages, doraSearch, openunmix, torchPackage ? python3Packages.torch, torchaudioPackage ? python3Packages.torchaudio }:

let
  rev = "b9ab48cad45976ba42b2ff17b229c071f0df9390";
  src = builtins.fetchGit {
    url = "https://github.com/adefossez/demucs.git";
    ref = "refs/heads/main";
    inherit rev;
  };
  effectiveOpenunmix = openunmix.override {
    inherit torchPackage torchaudioPackage;
  };
in
python3Packages.buildPythonApplication rec {
  pname = "demucs";
  version = "4.1.0a3+unstable.${lib.substring 0 7 rev}";

  inherit src;
  pyproject = true;

  build-system = [
    python3Packages.setuptools
  ];

  dependencies = [
    doraSearch
    python3Packages.einops
    python3Packages.julius
    effectiveOpenunmix
    python3Packages.pyyaml
    torchPackage
    torchaudioPackage
    python3Packages.tqdm
  ];

  postPatch = ''
    python - <<'PY'
    from pathlib import Path

    path = Path("demucs/audio.py")
    text = path.read_text()
    text = text.replace("import lameenc\n", "")
    text = text.replace(
        "    encoder = lameenc.Encoder()\n",
        "    import lameenc\n\n    encoder = lameenc.Encoder()\n",
    )
    path.write_text(text)
    PY

    cat > pyproject.toml <<EOF
    [build-system]
    requires = ["setuptools>=68"]
    build-backend = "setuptools.build_meta"
    EOF
  '';

  pythonImportsCheck = [ "demucs" ];

  meta = with lib; {
    description = "Music source separation CLI";
    homepage = "https://github.com/adefossez/demucs";
    license = licenses.mit;
    mainProgram = "demucs";
    platforms = platforms.unix;
  };
}
