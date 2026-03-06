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
from textwrap import dedent

pyproject = dedent(
    """
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
    """
).lstrip()
Path("pyproject.toml").write_text(pyproject)

path = Path("demucs_service/app.py")
text = path.read_text()

old = "def _sniff_mp3(file_storage) -> bool:\n"
insert = dedent(
    """\
    def check_cuda() -> tuple[dict | None, str | None]:
        try:
            return check_cuda_or_raise(), None
        except Exception as exc:
            return None, str(exc)


    def _sniff_mp3(file_storage) -> bool:
    """
)
if old not in text:
    raise RuntimeError("Expected _sniff_mp3 anchor was not found in demucs_service/app.py")
text = text.replace(old, insert, 1)

text = text.replace("    cuda_info = check_cuda_or_raise()\\n", "    check_cuda_or_raise()\\n", 1)

old = dedent(
    """\
    @app.get("/health")
    def health() -> object:
        return jsonify({"ok": True})

    @app.get("/api/status")
    def status() -> object:
        worker_status = worker.status()
        return jsonify(
            {
                "service": "demucs",
                "running_jobs": worker_status["running_jobs"],
                "max_concurrent_jobs": settings.max_concurrent_jobs,
                "storage_volume": _storage_volume_status(settings.storage_root),
                "cuda": cuda_info,
            }
        )
    """
)
replacement = dedent(
    """\
    @app.get("/health")
    def health() -> object:
        _, cuda_error = check_cuda()
        if cuda_error:
            return (
                jsonify(
                    {
                        "ok": False,
                        "error": "cuda_unavailable",
                        "message": cuda_error,
                    }
                ),
                503,
            )
        return jsonify({"ok": True})

    @app.get("/api/status")
    def status() -> object:
        worker_status = worker.status()
        cuda_info, cuda_error = check_cuda()
        return jsonify(
            {
                "service": "demucs",
                "running_jobs": worker_status["running_jobs"],
                "max_concurrent_jobs": settings.max_concurrent_jobs,
                "storage_volume": _storage_volume_status(settings.storage_root),
                "cuda": cuda_info,
                "cuda_error": cuda_error,
            }
        )
    """
)
if old not in text:
    raise RuntimeError("Expected /health + /api/status block was not found in demucs_service/app.py")
text = text.replace(old, replacement, 1)

old = dedent(
    """\
    @app.post("/api/jobs")
    def create_job() -> object:
        mode = request.form.get("mode", "4")
        model = request.form.get("model", settings.demucs_default_model)
    """
)
replacement = dedent(
    """\
    @app.post("/api/jobs")
    def create_job() -> object:
        mode = request.form.get("mode", "4")
        _, cuda_error = check_cuda()
        if cuda_error:
            return error_response("cuda_unavailable", cuda_error, 503)

        model = request.form.get("model", settings.demucs_default_model)
    """
)
if old not in text:
    raise RuntimeError("Expected /api/jobs block was not found in demucs_service/app.py")
text = text.replace(old, replacement, 1)

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
