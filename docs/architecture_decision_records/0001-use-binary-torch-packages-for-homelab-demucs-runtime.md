# ADR 0001: Use Binary Torch Packages for the Homelab Demucs Runtime

* Date: 2026-03-04
* Status: pending
* Deciders: Jake Stanley, Codex

## Context and Problem Statement

`homelab-demucs` is a useful host-local service, but it is not core operating system functionality. Building its CUDA-enabled runtime from source through `python3Packages.torchWithCuda` caused multi-hour rebuilds on `shrike`, made SSH responsiveness worse during compilation, and made clean install or disaster recovery workflows impractical.

The repository's design goal is that the system should be realistically rebuildable from a clean NixOS install and this repository. For heavyweight CUDA and ML runtimes, source builds on the target host are an unacceptable default. A decision is needed for how `homelab-demucs` should obtain its Torch runtime while preserving as much declarative NixOS structure as practical.

## Considered Options

- **Option 1**: Continue building the CUDA-enabled Torch stack from source in Nix
- **Option 2**: Use Nixpkgs binary Torch packages for the `homelab-demucs` runtime
- **Option 3**: Manage the Demucs runtime outside normal Nix packaging with `pip`, a venv, or a container

## Decision Outcome

Use the binary-package path already provided by pinned `nixpkgs` for the `homelab-demucs` runtime.

This is a short-term workaround, not the preferred steady-state architecture. The intended end state is to return to a more normal Nix source/package flow backed by a binary cache such as Cachix so target hosts do not perform heavyweight local ML builds.

Key implementation points:

- `homelab-demucs` remains a declarative NixOS-managed service.
- The Demucs CLI runtime uses `python3Packages.torch-bin` and `python3Packages.torchaudio-bin` instead of source-built `torchWithCuda`.
- The service-specific packaging remains in this repository, but the heaviest ML runtime is pulled from upstream binary wheel packaging maintained by Nixpkgs.
- This decision is scoped to `homelab-demucs` because it is not core OS functionality and because the source-build path is operationally too expensive.
- This workaround must not be generalized to other services by default. Any similar exception requires Jake Stanley's explicit decision.

## Consequences

- Positive outcomes
  - Rebuilds for `homelab-demucs` should avoid the worst-case multi-hour local Torch source build.
  - The service remains declarative and managed through the same NixOS workflow as the rest of the host.
  - The compromise is narrower and cleaner than introducing ad hoc runtime `pip` state.
- Negative impacts
  - The runtime now relies on prebuilt binary artifacts rather than a source-built Torch derivation.
  - This is less pure than a full source build and may require closer attention to binary compatibility.
  - Debugging binary-wheel integration issues may differ from debugging normal source builds.
  - This creates an explicit architectural exception that should be removed once binary caching is in place.
- Breaking changes (if any)
  - None intended at the service interface level.

## Pros and Cons of the Options

### Option 1: Continue building the CUDA-enabled Torch stack from source in Nix
**Pros:**
- Maximally pure and reproducible within the Nix source-build model.
- Keeps all runtime components built under one consistent derivation graph.

**Cons:**
- Multi-hour local rebuilds on `shrike` are unacceptable for initial install and recovery.
- Heavy builds can degrade host responsiveness and make remote administration less reliable.

### Option 2: Use Nixpkgs binary Torch packages for the `homelab-demucs` runtime
**Pros:**
- Preserves declarative NixOS management.
- Uses an upstream Nixpkgs-supported compromise instead of inventing a custom wheel workflow.
- Greatly reduces the cost of deploying a non-core ML service.

**Cons:**
- Less pure than building Torch from source.
- Depends on the availability and compatibility of the binary package path in pinned Nixpkgs.

### Option 3: Manage the Demucs runtime outside normal Nix packaging with `pip`, a venv, or a container
**Pros:**
- Fastest route to getting the service running.
- Avoids much of the Nix packaging friction for ML dependencies.

**Cons:**
- Weakens the repository's declarative system model.
- Adds imperative or semi-imperative runtime state and a second package-management surface.
- Harder to reason about during rebuilds, restores, and upgrades.

## Notes

- This record is marked `pending` until the binary-package path is validated on `shrike`.
- This workaround is temporary. The preferred follow-up is to set up Cachix or another binary cache and then reassess whether this exception is still needed.
- Even if this compromise works, it must remain an explicit exception rather than becoming the default for core system components or future services.
- A future binary cache such as Cachix is the preferred long-term solution, especially for custom service packages and any remaining heavyweight derivations.
- The temporary local `dora-search` shim used by `homelab-demucs` should be revisited separately once the runtime path is stable.
