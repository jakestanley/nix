#!/usr/bin/env bash
set -euo pipefail

if ! command -v demucs >/dev/null 2>&1; then
  echo "demucs not found in PATH" >&2
  exit 1
fi

demucs_bin="$(command -v demucs)"
echo "demucs_bin=$demucs_bin"
demucs --help >/dev/null

python_bin="$(sed -n '1s/^#!//p' "$demucs_bin" || true)"
if [[ -z "$python_bin" || ! -x "$python_bin" ]]; then
  if command -v python3 >/dev/null 2>&1; then
    python_bin="$(command -v python3)"
  else
    echo "python interpreter not found for CUDA check" >&2
    exit 1
  fi
fi

"$python_bin" - <<'PY'
import torch
import torchaudio

print(f"torch={torch.__version__}")
print(f"torchaudio={torchaudio.__version__}")
print(f"cuda_compiled={torch.version.cuda}")
print(f"cuda_available={torch.cuda.is_available()}")
print(f"cuda_device_count={torch.cuda.device_count()}")

if not torch.cuda.is_available():
    raise SystemExit("CUDA is not available to torch")
PY

echo "demucs CUDA smoke check passed"
