{ lib, config, ... }:

{
  home.file = {
    "Desktop/Dock Folders/Work/Microsoft Teams.app".source =
      config.lib.file.mkOutOfStoreSymlink "/Applications/Microsoft Teams.app";
    "Desktop/Dock Folders/Work/Microsoft Outlook.app".source =
      config.lib.file.mkOutOfStoreSymlink "/Applications/Microsoft Outlook.app";
    "Desktop/Dock Folders/Work/Google Chrome.app".source =
      config.lib.file.mkOutOfStoreSymlink "/Applications/Nix Apps/Google Chrome.app";
    "Desktop/Dock Folders/Work/WorkSpaces.app".source =
      config.lib.file.mkOutOfStoreSymlink "/Applications/WorkSpaces.app";
    "Desktop/Dock Folders/Music/Flight Deck.app".source =
      config.lib.file.mkOutOfStoreSymlink "/Applications/Flight Deck.app";
    "Desktop/Dock Folders/Music/Music.app".source =
      config.lib.file.mkOutOfStoreSymlink "/System/Applications/Music.app";
    "Desktop/Dock Folders/Music/Ableton Live 11 Standard.app".source =
      config.lib.file.mkOutOfStoreSymlink "/Applications/Ableton Live 11 Standard.app";
    "Desktop/Dock Folders/Music/GarageBand.app".source =
      config.lib.file.mkOutOfStoreSymlink "/Applications/GarageBand.app";
    "Desktop/Dock Folders/Music/Guitar Pro 8.app".source =
      config.lib.file.mkOutOfStoreSymlink "/Applications/Guitar Pro 8.app";
    "Desktop/Dock Folders/Music/Mixed In Key 11.app".source =
      config.lib.file.mkOutOfStoreSymlink "/Applications/Mixed In Key 11.app";

    "Desktop/Dock Folders/Development/Blender.app".source =
      config.lib.file.mkOutOfStoreSymlink "/Applications/Blender.app";
    "Desktop/Dock Folders/Development/Cyberduck.app".source =
      config.lib.file.mkOutOfStoreSymlink "/Applications/Nix Apps/Cyberduck.app";
    "Desktop/Dock Folders/Development/Godot.app".source =
      config.lib.file.mkOutOfStoreSymlink "/Applications/Godot.app";
    "Desktop/Dock Folders/Development/Godot 3.5.1.app".source =
      config.lib.file.mkOutOfStoreSymlink "/Applications/Godot 3.5.1.app";

    "Desktop/Dock Folders/Games/Fallout II Community Edition.app".source =
      config.lib.file.mkOutOfStoreSymlink "/Applications/Fallout 2/Fallout II Community Edition.app";

    "Desktop/Dock Folders/Work/IDEA.app".source =
      config.lib.file.mkOutOfStoreSymlink "/Users/jake/Applications/IntelliJ IDEA Ultimate.app";
    "Desktop/Dock Folders/Work/Microsoft Excel.app".source =
      config.lib.file.mkOutOfStoreSymlink "/Applications/Microsoft Excel.app";
    "Desktop/Dock Folders/Work/Microsoft Word.app".source =
      config.lib.file.mkOutOfStoreSymlink "/Applications/Microsoft Word.app";
  };

  home.sessionPath = [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "$HOME/bin"
    "$HOME/bin/ffmpeg-scripts"
    "$HOME/.local/bin"
    "$HOME/.cargo/bin"
    "$HOME/.dotnet/tools"
    "$HOME/.lmstudio/bin"
    "$HOME/.npm/.bin"
    "$HOME/.pilau/lemonbar"
    "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
    "$HOME/.nvm/bin"
  ];

  programs.zsh = {
    oh-my-zsh = {
      enable = lib.mkForce true;
      theme = "robbyrussell";
      plugins = [
        "git"
        "docker"
      ];
    };

    # Keep this host-specific until explicitly promoted into common shell.nix.
    initContent = lib.mkBefore ''
      # SDKMAN and Node version manager helpers.
      [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
      [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
      [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
    '';

    profileExtra = ''
      export SDKMAN_DIR="''${SDKMAN_DIR:-$HOME/.sdkman}"
      export NVM_DIR="''${NVM_DIR:-$HOME/.nvm}"
      export GOPATH="''${GOPATH:-$HOME/go}"
      export SHELLCHECK_OPTS="''${SHELLCHECK_OPTS:--e SC2086}"

      if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      fi

      export MANPATH="$HOME/.local/share/man:$MANPATH"
    '';
  };
}
