{ lib, ... }:

{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "find . -type d \\( -name .git -o -name node_modules \\) -prune -o -type f -print 2>/dev/null";
    fileWidgetCommand = "find . -type d \\( -name .git -o -name node_modules \\) -prune -o -type f -print 2>/dev/null";
    changeDirWidgetCommand = "find . -type d \\( -name .git -o -name node_modules \\) -prune -o -type d -print 2>/dev/null";
  };

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
      UNIXCFG_REPO="''${UNIXCFG_REPO:-$HOME/git/github.com/jakestanley/nix}"

      # SDKMAN and Node version manager helpers.
      [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
      [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
      [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

      # Machine-specific hooks stay outside version control.
      local_rc="''${ZDOTDIR:-$HOME}/.zshrc.local"
      [[ -f "$local_rc" ]] && source "$local_rc"

      # If we're inside GNU screen, annotate the prompt.
      if (( ''${+functions[_dotfiles_prompt_apply_screen_prefix]} )); then
        if ! (( ''${precmd_functions[(Ie)_dotfiles_prompt_apply_screen_prefix]} )); then
          precmd_functions+=(_dotfiles_prompt_apply_screen_prefix)
        fi
      fi

      # Load local alias/function overrides after HM shellAliases so local,
      # untracked work aliases can override tracked defaults when needed.
      typeset -gi _turing_local_overrides_loaded=0
      _turing_load_local_shell_overrides() {
        (( _turing_local_overrides_loaded )) && return
        _turing_local_overrides_loaded=1

        local local_aliases="''${ZDOTDIR:-$HOME}/.zsh_aliases"
        [[ -r "$local_aliases" ]] && source "$local_aliases"

        local local_functions="''${ZDOTDIR:-$HOME}/.zsh_functions"
        [[ -r "$local_functions" ]] && source "$local_functions"
      }

      autoload -Uz add-zsh-hook
      add-zsh-hook precmd _turing_load_local_shell_overrides
    '';

    profileExtra = ''
      export SDKMAN_DIR="''${SDKMAN_DIR:-$HOME/.sdkman}"
      export NVM_DIR="''${NVM_DIR:-$HOME/.nvm}"
      export GOPATH="''${GOPATH:-$HOME/go}"
      export VISUAL="''${VISUAL:-vim}"
      export SVN_EDITOR="''${SVN_EDITOR:-vim}"
      export EDITOR="''${EDITOR:-vim}"
      export SHELLCHECK_OPTS="''${SHELLCHECK_OPTS:--e SC2086}"
      export UNIXCFG_REPO="''${UNIXCFG_REPO:-$HOME/git/github.com/jakestanley/nix}"

      if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      fi

      path_unshift() {
        local dir="$1"
        if [[ -n "$dir" && -d "$dir" && ":$PATH:" != *":$dir:"* ]]; then
          PATH="$dir:$PATH"
        fi
      }

      path_unshift "$HOME/bin"
      path_unshift "$HOME/bin/ffmpeg-scripts"
      path_unshift "$HOME/.local/bin"
      path_unshift "$HOME/.cargo/bin"
      path_unshift "$HOME/.dotnet/tools"
      path_unshift "$HOME/.lmstudio/bin"
      path_unshift "$HOME/.npm/.bin"
      path_unshift "$HOME/.pilau/lemonbar"
      path_unshift "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
      path_unshift "$NVM_DIR/bin"
      export PATH

      export MANPATH="$HOME/.local/share/man:$MANPATH"

      local_profile="''${ZDOTDIR:-$HOME}/.zprofile.local"
      [[ -f "$local_profile" ]] && source "$local_profile"
    '';
  };
}
