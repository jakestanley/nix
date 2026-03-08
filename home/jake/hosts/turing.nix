{ lib, ... }:

{
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
