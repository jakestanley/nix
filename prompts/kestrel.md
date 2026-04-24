You are helping extend the nixos-shrike flake repository to support a new work VM called `kestrel`.

## Goal for this session (Phase 1 only)

Configure the NixOS host `shrike` to run and manage a libvirt/QEMU VM. Do NOT implement the kestrel guest config (Phase 3) — only lay the groundwork on the shrike host side.

## Repo orientation

Before making any changes, read and understand:
- `flake.nix` — understand `mkNixosHost` and how host modules are composed
- `hosts/shrike/default.nix` — understand shrike's current module structure and imports
- `modules/nixos/` — understand existing module patterns before creating new ones
- Any existing network configuration on shrike — note what is already declared before touching it

Do not guess at structure. If the existing pattern for a given concern (networking, profiles, services) is not clear from reading the repo, stop and ask before proceeding.

## What to implement

### 1. Bridge network on shrike

Add a bridge interface (`br0`) to shrike's network config to allow the kestrel VM to appear as a first-class host on the LAN (`10.92.8.x` subnet — confirm the actual subnet and NIC name by reading existing network config first).

- If shrike already has network config declared, extend it carefully
- If the NIC name is not obvious from existing config, ask before assuming
- Do not remove or break existing connectivity

### 2. libvirt + QEMU on shrike

Create `hosts/shrike/virtualisation.nix` (following the existing per-host module pattern) containing:

- `virtualisation.libvirtd` with QEMU/KVM, UEFI (OVMF), and TPM emulation (swtpm)
- The current user (`jake`) added to the `libvirtd` group
- `cockpit` service on port 9090 with `cockpit-machines` for VM management
- Firewall rule allowing port 9090 inbound on the LAN interface only

Import this module from `hosts/shrike/default.nix`.

### 3. Profile gating

The VM and Cockpit services must not run when the gaming profile is active. Review how profile gating is currently implemented on shrike before deciding how to integrate. Do not invent a new pattern — follow what already exists.

If the existing profile mechanism does not cleanly support conditional service enablement, stop and describe the options before implementing anything.

### 4. Managed save (suspend to disk)

No explicit Nix config is needed for this — libvirt's managed save works via `virsh managedsave` / Cockpit UI. Add a comment in `virtualisation.nix` noting that kestrel should be suspended via managed save rather than shut down, and that 16GB of disk headroom is required on the host for the save image.

## What NOT to implement

- Do not create a `nixosConfiguration` entry for kestrel in `flake.nix` — kestrel is an Ubuntu guest, not a NixOS host
- Do not configure adler (nginx proxy, dnsmasq) — that is handled separately in the homelab-infra repo
- Do not implement the kestrel guest config (xrdp, VPN, home-manager) — that is Phase 3 and requires manual first-boot steps first

## Phase 3 hint (documentation only)

Add a `hosts/shrike/kestrel/README.md` noting:
- kestrel is an Ubuntu 26.04 LTS ("Resolute Raccoon") VM
- 16GB RAM, 4 vCPUs, 256GB disk, bridged network
- After first boot: retrieve kestrel's host SSH key, add to `identities.nix`, re-encrypt agenix secrets
- Guest config will include: home-manager, xrdp + KDE Plasma, full-tunnel VPN with static LAN route for `10.92.8.0/24` to keep SSH/RDP reachable while VPN is active, inbound ports 22 and 3389 declared explicitly

## Constraints

- Follow existing module and import patterns exactly — do not introduce new structural patterns without asking
- Run `nix flake check` after changes and fix any errors before finishing
- Do not rebuild or deploy — this is config only
- If anything is ambiguous (NIC names, profile mechanism, import conventions), ask before acting