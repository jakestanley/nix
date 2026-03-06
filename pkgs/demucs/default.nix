{ lib, python3Packages, juliusPackage ? python3Packages.julius, torchPackage ? python3Packages.torch, torchaudioPackage ? python3Packages.torchaudio }:

let
  rev = "b9ab48cad45976ba42b2ff17b229c071f0df9390";
  src = builtins.fetchGit {
    url = "https://github.com/adefossez/demucs.git";
    ref = "refs/heads/main";
    inherit rev;
  };
  doraSearch = python3Packages.buildPythonPackage rec {
    pname = "dora-search";
    version = "0.0.0+compat";
    src = ../dora-search/src;
    pyproject = true;

    build-system = [
      python3Packages.setuptools
    ];

    postPatch = ''
      cat > pyproject.toml <<EOF
      [build-system]
      requires = ["setuptools>=68"]
      build-backend = "setuptools.build_meta"

      [project]
      name = "dora-search"
      version = "${version}"
      description = "Minimal runtime compatibility shim for Demucs"
      requires-python = ">=3.11"

      [tool.setuptools]
      include-package-data = true

      [tool.setuptools.packages.find]
      include = ["dora"]
      EOF
    '';

    pythonImportsCheck = [ "dora" "dora.log" ];
  };
  openunmix = python3Packages.buildPythonApplication rec {
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

    pythonImportsCheck = [ "openunmix" "openunmix.filtering" ];
  };
  effectiveOpenunmix = openunmix.overrideAttrs (_: {
    dontCheckRuntimeDeps = true;
  });
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
    text = text.replace("import numpy as np\n", "import numpy as np\nimport soundfile as sf\n")
    text = text.replace(
        "    encoder = lameenc.Encoder()\n",
        "    import lameenc\n\n    encoder = lameenc.Encoder()\n",
    )
    text = text.replace(
        "        ta.save(str(path), wav, sample_rate=samplerate,\n"
        "                encoding=encoding, bits_per_sample=bits_per_sample)\n",
        "        subtype = 'FLOAT' if as_float else f'PCM_{bits_per_sample}'\n"
        "        sf.write(str(path), wav.t().cpu().numpy(), samplerate,\n"
        "                 format='WAV', subtype=subtype)\n",
    )
    text = text.replace(
        "        ta.save(str(path), wav, sample_rate=samplerate, bits_per_sample=bits_per_sample)\n",
        "        sf.write(str(path), wav.t().cpu().numpy(), samplerate,\n"
        "                 format='FLAC', subtype=f'PCM_{bits_per_sample}')\n",
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
