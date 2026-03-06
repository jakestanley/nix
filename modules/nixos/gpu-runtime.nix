{ ... }:

{
  # Shared CUDA build/runtime switch used by multiple GPU-backed services.
  nixpkgs.config.cudaSupport = true;
}
