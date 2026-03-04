{ lib, python3Packages, fetchPypi }:

python3Packages.buildPythonPackage rec {
  pname = "rcon";
  version = "2.4.9";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-1BqDEdwTNS2jUWP0ajzBPrIPXN4Sl7dbVudkXvdtCkg=";
  };

  build-system = [
    python3Packages.setuptools
  ];

  pythonImportsCheck = [
    "rcon"
    "rcon.source"
  ];

  meta = with lib; {
    description = "Client library and tools for remote console access";
    homepage = "https://pypi.org/project/rcon/";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
