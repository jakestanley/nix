{ ... }:

{
  # Adopt Homebrew declaratively without removing unmanaged packages yet.
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };

    # use `brew leaves --installed-on-request` to compile these lists in future
    brews = [
      "readline"
      "bash"
      "docker"
      "wireguard-tools"
      "ncdu"
      "awscli"
      "openconnect"
      "pipx"
    ];

    casks = [
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
      # "wireguard"
      # guitar pro is currently broken via brew, requires manual download
      # "guitar-pro"
    ];
  };
}

