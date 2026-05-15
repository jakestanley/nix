{ pkgs, ... }:

{
  # ── Firewall ──────────────────────────────────────────────────────────────
  # nftables-backed stateful firewall. openssh opens port 22 automatically
  # via services.openssh.openFirewall (default: true).
  networking.nftables.enable = true;
  networking.firewall.enable = true;

  # ── SSH hardening ─────────────────────────────────────────────────────────
  # Supplements modules/nixos/ssh.nix with stricter settings for a machine
  # that holds VPN credentials and SSH keys.
  services.openssh.settings = {
    # Restrict logins to the named account only.
    AllowUsers = [ "jake" ];
    # Disable TCP tunnelling through kestrel (reduces lateral-movement risk).
    # Re-enable per-connection with `ssh -L` / `ssh -R` flags if needed.
    AllowTcpForwarding = "no";
    # Disable agent forwarding — agent material is exposed to remote root.
    AllowAgentForwarding = "no";
    # Prefer encrypted ClientAlive keepalives over plain TCP keepalives.
    TCPKeepAlive = "no";
    ClientAliveCountMax = 2;
    # Reduce brute-force window.
    MaxAuthTries = 3;
    # VERBOSE logs fingerprint of each accepted key (useful for key auditing).
    LogLevel = "VERBOSE";
  };

  # Warning banner shown to clients before authentication.
  services.openssh.settings.Banner = toString (pkgs.writeText "sshd-banner" ''
    Authorized access only. All activity is logged and audited.
  '');

  # ── Kernel sysctl hardening ───────────────────────────────────────────────
  boot.kernel.sysctl = {
    # Prevent auto-loading of TTY line disciplines (reduces kernel attack surface).
    "dev.tty.ldisc_autoload" = 0;

    # Prevent creating hard links / opening FIFOs or regular files in sticky
    # dirs by non-owners — mitigates several privilege-escalation classes.
    "fs.protected_fifos" = 2;
    "fs.protected_regular" = 2;

    # Prevent SUID binaries from producing core dumps (avoids credential leakage).
    "fs.suid_dumpable" = 0;

    # Hide kernel symbol addresses from unprivileged processes.
    "kernel.kptr_restrict" = 2;

    # Disable magic SysRq key (prevents local crash/reboot attacks on unattended machine).
    "kernel.sysrq" = 0;

    # Prevent unprivileged BPF programs — significant kernel attack surface.
    "kernel.unprivileged_bpf_disabled" = 1;

    # Harden BPF JIT against JIT-spray attacks.
    "net.core.bpf_jit_harden" = 2;

    # Reject ICMP redirect messages (prevents routing-table poisoning).
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;

    # Log packets with impossible/spoofed source addresses.
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.default.log_martians" = 1;

    # Loose reverse-path filtering — drop packets whose source is not reachable
    # via the interface they arrived on. Set to 2 if a VPN causes routing issues.
    "net.ipv4.conf.all.rp_filter" = 1;

    # Don't send ICMP redirects — kestrel is not a router.
    "net.ipv4.conf.all.send_redirects" = 0;
  };

  # ── Blacklist unused network protocols ────────────────────────────────────
  # None of dccp/sctp/rds/tipc are used on kestrel; blacklisting them removes
  # attack surface. Appended to base.nix's extraModprobeConfig (string merge).
  boot.extraModprobeConfig = ''
    install dccp /bin/false
    install sctp /bin/false
    install rds /bin/false
    install tipc /bin/false
  '';

  # ── Audit daemon ──────────────────────────────────────────────────────────
  # Records security-relevant kernel events: auth, privilege escalation,
  # syscall anomalies. Logs go to /var/log/audit/audit.log.
  security.auditd.enable = true;
}
