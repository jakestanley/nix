{ ... }:

{
  # Adopt Homebrew declaratively without removing unmanaged packages yet.
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      # Choosing uninstall over zap, as I need to do awkward shit like install python@3.12, which
      #   doesn't work with brews. Using uninstall will prevent nix from deleting ad-hoc installed
      #   packages, whereas zap keeps it clean and declarative. compromises
      cleanup = "uninstall";
    };

    # use `brew leaves --installed-on-request` to compile these lists in future
    brews = [
      "dsda-doom"
      "aubio"
      "cassandra"
      "cmake"
      "ghostscript"
      "sox"
      "summarize"
      "wireguard-tools"
      "woodpecker-cli"
      "yakitrak/yakitrak/obsidian-cli"
    ];

    casks = [
      "moonlight"
      "vlc"
      "godot"
      "claude"
      "gog-galaxy"
      "microsoft-teams"
      "dropbox"
      "1password"
      "duplicate-file-finder"
      "energiza"
      "istatistica-core"
      "ledger-wallet"
      "microsoft-excel"
      "microsoft-outlook"
      "microsoft-powerpoint"
      "microsoft-word"
      "spotify"
      "whatsapp"
      "windows-app"
      "amazon-workspaces"
      "visual-studio-code"
      "obsidian"
      "obs"
      "ableton-live-standard@11"
      "mixed-in-key"
      "font-ubuntu-mono-nerd-font"
      "omnidisksweeper"
      "steam"
      "blender"
      "gimp"
      "bambu-studio"
      "protonvpn"
      "macs-fan-control"
      "inkscape"
      "prismlauncher"
    ];
  };
}
