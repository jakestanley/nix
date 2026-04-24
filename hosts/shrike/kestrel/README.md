# kestrel

kestrel is an Ubuntu 26.04 LTS ("Resolute Raccoon") VM running on shrike via libvirt/QEMU.

## Specs

- 16 GB RAM, 4 vCPUs, 256 GB disk
- Bridged network (br0 → enp4s0), appears as first-class host on 10.92.8.x LAN

## Managed save

Suspend kestrel via managed save rather than shutdown:

```
virsh managedsave kestrel
```

Or use the Cockpit UI (port 9090). The save image requires ~16 GB of free disk space on
the host.

## First-boot steps (required before Phase 3 guest config)

1. Retrieve kestrel's host SSH key and add to `modules/nixos/identities.nix`
2. Re-encrypt any agenix secrets that target kestrel

## Phase 3 guest config (home-manager, xrdp, VPN)

- home-manager
- xrdp + KDE Plasma desktop
- Full-tunnel VPN with a static LAN route for `10.92.8.0/24` to keep SSH (port 22) and
  RDP (port 3389) reachable while the VPN is active
- Inbound firewall rules: ports 22 and 3389 declared explicitly