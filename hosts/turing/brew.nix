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
      "openconnect"
    ];

    casks = [
      "moonlight"
      "vlc"
      "chatgpt"
      "godot"
      "postman"
      "claude"
      "gog-galaxy"
      "google-chrome"
      "microsoft-teams"
      "prismlauncher"
      "dropbox"
      "1password"
      "cyberduck"
      "duplicate-file-finder"
      "energiza"
      "istatistica-core"
      "ledger-wallet"
      "microsoft-excel"
      "microsoft-outlook"
      "microsoft-powerpoint"
      "microsoft-word"
      "upscayl"
      "spotify"
      "whatsapp"
      "windows-app"
      "amazon-workspaces"
      "zoom"
      "visual-studio-code"
      "obsidian"
      "ableton-live-standard@11"
      "mixed-in-key"
      "discord"
      "font-ubuntu-mono-nerd-font"
      "omnidisksweeper"
      "steam"
      "blender"
      "gimp"
      "bambu-studio"
    ];
  };
}

