{ lib, python3Packages, doraSearch, openunmix, juliusPackage ? python3Packages.julius, torchPackage ? python3Packages.torch, torchaudioPackage ? python3Packages.torchaudio }:

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
  effectiveJulius = juliusPackage.override {
    torch = torchPackage;
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
    effectiveJulius
    effectiveOpenunmix
    python3Packages.omegaconf
    python3Packages.pyyaml
    python3Packages.soundfile
    torchPackage
    torchaudioPackage
    python3Packages.tqdm
  ];

  # The service uses a deliberately curated runtime: lazy MP3 support and
  # binary torchaudio packages do not satisfy upstream wheel metadata exactly.
  dontCheckRuntimeDeps = true;

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
