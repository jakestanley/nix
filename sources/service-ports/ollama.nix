{
  # Canonical local listen port for service 'ollama'.
  #
  # Synced from:
  # repo: git@github.com:jakestanley/homelab-infra.git
  # ref: main
  # rev: b5620c88b35ebe60376095f952f38faf0257e937
  # path: services.ollama.upstream.port in registry.yaml
  #
  # This value may be updated by scripts/sync-service-port.sh.
  # It must not be resolved dynamically during Nix evaluation or deployment.
  port = 20030;
}
