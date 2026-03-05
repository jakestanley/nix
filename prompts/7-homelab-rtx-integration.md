Implement an idiomatic NixOS integration for the `homelab-rtx` service.

Context:
- Source repo: `git@github.com:jakestanley/homelab-rtx.git` (branch: `systemd`)
- That repo now has Linux systemd support for generic hosts, but for NixOS we want the more idiomatic end state.
- The Python app in `homelab-rtx/app.py` now exposes a clean `main()` entrypoint.
- We do NOT want to runtime-clone the repo into `/srv/rtx`.
- We do NOT want to rely on repo-local `.venv` or `scripts/up.sh` for NixOS.
- We DO want immutable code in the Nix store and mutable state under `/var/lib/rtx`.

Task:
1. Package `homelab-rtx` in this repo’s Nix code from a pinned source.
2. Create a NixOS module or equivalent host-local module for the service.
3. Expose declarative options at least for:
   - enable
   - package
   - bindHost
   - port
   - environmentFile
   - extraEnvironment
4. Define a systemd service for `rtx` with:
   - `DynamicUser = true`
   - `StateDirectory = "rtx"`
   - `WorkingDirectory = "/var/lib/rtx"`
   - `Restart = "on-failure"`
   - journald logging
   - `ExecStart` using the packaged executable, not `scripts/up.sh`
5. Set default environment values:
   - `RTX_BIND_HOST`
   - `RTX_PORT`
   - `RTX_LOG_PATH=/var/lib/rtx/gpu-metrics.csv`
   - `RTX_LOG_INTERVAL_SECONDS=30`
   - `RTX_QUERY_TIMEOUT_SECONDS=5`
6. Ensure the service can resolve and execute `nvidia-smi`.
7. Do not add ingress, firewall, DNS, reverse proxy, or registry parsing logic here.
8. Add docs/comments showing how a host enables the module.

Implementation notes:
- Prefer a proper Python package/launcher in Nix over shell wrappers.
- If needed, add a small launcher that imports `app.main()` and executes it.
- Keep mutable files out of the source tree.
- Keep the module reusable rather than hardcoding host-specific values.
- Preserve the existing service contract and environment variable names from `homelab-rtx`.

Validation:
- `nix build`
- `nix flake check` if applicable
- confirm the generated unit uses `/var/lib/rtx`
- confirm `ExecStart` points into the Nix store
- confirm the service does not depend on `/srv/rtx`, `.venv`, or runtime git state
