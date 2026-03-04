{
  # Canonical local listen port for service 'arcade'.
  #
  # Synced from:
  # repo: git@github.com:jakestanley/homelab-infra.git
  # ref: main
  # rev: cf92ab5c27fbb9f3019d219388080c75a67eb8cd
  # path: services.arcade.upstream.port in registry.yaml
  #
  # This value may be updated by scripts/sync-service-port.sh.
  # It must not be resolved dynamically during Nix evaluation or deployment.
  port = 20032;
}
