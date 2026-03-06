{ lib, python3Packages, torchPackage ? python3Packages.torch }:

let
  src = builtins.fetchGit {
    url = "https://github.com/jakestanley/homelab-demucs.git";
    ref = "refs/heads/main";
    rev = "0f1f44c15793033ddd1f9f676267bd0f3a0a5518";
  };
in
python3Packages.buildPythonApplication rec {
  pname = "homelab-demucs";
  version = "0.0.0+unstable.0f1f44c";

  # Pinned public source fetched at build/evaluation time.
  inherit src;

  pyproject = true;

  build-system = with python3Packages; [
    setuptools
  ];

  dependencies = with python3Packages; [
    flask
    python-dotenv
    waitress
    torchPackage
  ];

  postPatch = ''
python - <<'PY'
from pathlib import Path
import re

pyproject = """
[build-system]
requires = ["setuptools>=68"]
build-backend = "setuptools.build_meta"

[project]
name = "homelab-demucs"
version = "${version}"
description = "Host-run HTTP service for Demucs separation jobs"
requires-python = ">=3.11"

[project.scripts]
homelab-demucs = "demucs_service.server:main"

[tool.setuptools.packages.find]
include = ["demucs_service"]

[tool.setuptools.package-data]
demucs_service = ["static/*.html", "openapi.json"]
""".lstrip()
Path("pyproject.toml").write_text(pyproject)

path = Path("demucs_service/app.py")
text = path.read_text()

check_cuda_fn = (
    "def check_cuda() -> tuple[dict | None, str | None]:\n"
    "    try:\n"
    "        return check_cuda_or_raise(), None\n"
    "    except Exception as exc:\n"
    "        return None, str(exc)\n"
)
if "def check_cuda() -> tuple[dict | None, str | None]:" not in text:
    sniff_anchor = "def _sniff_mp3(file_storage) -> bool:\n"
    if sniff_anchor in text:
        text = text.replace(sniff_anchor, f"{check_cuda_fn}\n{sniff_anchor}", 1)
    else:
        print("warning: demucs_service/app.py missing _sniff_mp3 anchor; skipped check_cuda insertion")

text = text.replace("    cuda_info = check_cuda_or_raise()\n", "    check_cuda_or_raise()\n", 1)

if '"error": "cuda_unavailable"' not in text:
    health_pattern = re.compile(
        r'    @app\.get\("/health"\)\n'
        r'    def health\(\) -> object:\n'
        r'(?:        .*\n|\n)*?(?=\n    @app\.get\("/api/status"\)\n)',
        re.S,
    )
    health_replacement = (
        '    @app.get("/health")\n'
        '    def health() -> object:\n'
        '        _, cuda_error = check_cuda()\n'
        '        if cuda_error:\n'
        '            return (\n'
        '                jsonify(\n'
        '                    {\n'
        '                        "ok": False,\n'
        '                        "error": "cuda_unavailable",\n'
        '                        "message": cuda_error,\n'
        '                    }\n'
        '                ),\n'
        '                503,\n'
        '            )\n'
        '        return jsonify({"ok": True})\n'
    ).rstrip("\n")
    text, replaced = health_pattern.subn(health_replacement, text, count=1)
    if replaced == 0:
        print("warning: demucs_service/app.py missing /health block anchor; skipped /health patch")

if '"cuda_error": cuda_error' not in text:
    status_pattern = re.compile(
        r'    @app\.get\("/api/status"\)\n'
        r'    def status\(\) -> object:\n'
        r'(?:        .*\n|\n)*?(?=\n    @app\.post\("/api/admin/clear-caches"\)\n)',
        re.S,
    )
    status_replacement = (
        '    @app.get("/api/status")\n'
        '    def status() -> object:\n'
        '        worker_status = worker.status()\n'
        '        cuda_info, cuda_error = check_cuda()\n'
        '        return jsonify(\n'
        '            {\n'
        '                "service": "demucs",\n'
        '                "running_jobs": worker_status["running_jobs"],\n'
        '                "max_concurrent_jobs": settings.max_concurrent_jobs,\n'
        '                "storage_volume": _storage_volume_status(settings.storage_root),\n'
        '                "cuda": cuda_info,\n'
        '                "cuda_error": cuda_error,\n'
        '            }\n'
        '        )\n'
    ).rstrip("\n")
    text, replaced = status_pattern.subn(status_replacement, text, count=1)
    if replaced == 0:
        print("warning: demucs_service/app.py missing /api/status block anchor; skipped /api/status patch")

if 'return error_response("cuda_unavailable", cuda_error, 503)' not in text:
    job_anchor = '    @app.post("/api/jobs")\n    def create_job() -> object:\n'
    job_insertion = (
        '        _, cuda_error = check_cuda()\n'
        '        if cuda_error:\n'
        '            return error_response("cuda_unavailable", cuda_error, 503)\n'
        '\n'
    )
    if job_anchor in text:
        text = text.replace(job_anchor, f"{job_anchor}{job_insertion}", 1)
    else:
        print("warning: demucs_service/app.py missing /api/jobs anchor; skipped /api/jobs patch")

path.write_text(text)
PY
  '';

  pythonImportsCheck = [ "demucs_service" ];

  meta = with lib; {
    description = "Host-run Demucs separation service";
    homepage = "https://github.com/jakestanley/homelab-demucs";
    mainProgram = "homelab-demucs";
    platforms = platforms.unix;
  };
}
