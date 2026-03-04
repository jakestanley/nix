{ lib, python3Packages }:

python3Packages.buildPythonPackage rec {
  pname = "dora-search";
  version = "0.0.0+compat";

  src = ./src;
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

  meta = with lib; {
    description = "Minimal Dora runtime shim for Demucs CLI usage";
    homepage = "https://github.com/facebookresearch/dora";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
