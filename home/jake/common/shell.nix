{ config, lib, pkgs, ... }:

let
  editorEnv = import ../../../modules/shared/editor-env.nix;
  fzfPruneDirs = [ ".git" "node_modules" ];
  fzfIgnoreFiles = [ "*.class" ];
  mkNameExpr = patterns: lib.concatStringsSep " -o " (map (p: "-name ${lib.escapeShellArg p}") patterns);
  fzfPruneExpr = mkNameExpr fzfPruneDirs;
  fzfFileIgnoreExpr = mkNameExpr fzfIgnoreFiles;
  fzfPatternArgs = lib.concatStringsSep " " (map lib.escapeShellArg (fzfPruneDirs ++ fzfIgnoreFiles));
  fzfFileCommand =
    "find ."
    + lib.optionalString (fzfPruneDirs != []) " -type d \\( ${fzfPruneExpr} \\) -prune -o"
    + " -type f"
    + lib.optionalString (fzfIgnoreFiles != []) " -not \\( ${fzfFileIgnoreExpr} \\)"
    + " -print 2>/dev/null";
  fzfDirCommand =
    "find ."
    + lib.optionalString (fzfPruneDirs != []) " -type d \\( ${fzfPruneExpr} \\) -prune -o"
    + " -type d -print 2>/dev/null";
  tmuxAuto = pkgs.writeShellApplication {
    name = "tmux-auto";
    runtimeInputs = [ pkgs.tmux ];
    text = builtins.readFile ../../../scripts/tmux-auto.sh;
  };
in

{
  home.activation.ensureLocalZshOverrides = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for file in \
      "${config.home.homeDirectory}/.zsh_aliases" \
      "${config.home.homeDirectory}/.zsh_functions"
    do
      if [ ! -e "$file" ]; then
        $DRY_RUN_CMD touch "$file"
        $DRY_RUN_CMD chmod 0644 "$file"
      fi
    done
  '';

  home.packages = [ tmuxAuto ];

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = fzfFileCommand;
    fileWidgetCommand = fzfFileCommand;
    changeDirWidgetCommand = fzfDirCommand;
  };

  programs.zsh = {
    autocd = false;
    history = {
      append = true;
      ignoreAllDups = true;
    };
    setOptions = [
      "HIST_REDUCE_BLANKS"
    ];

    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    siteFunctions = import ./zsh-functions.nix;
    initContent = ''
      bindkey '^R' history-incremental-search-backward
      typeset -gaU FZF_IGNORE_PATTERNS
      FZF_IGNORE_PATTERNS+=( ${fzfPatternArgs} )
      ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
        rfcdate() {
          date -Idate
        }
      ''}
      ${lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
        rfcdate() {
          date --rfc-3339=date
        }
      ''}

      # Load local alias/function overrides after HM shellAliases so local,
      # untracked work aliases can override tracked defaults when needed.
      typeset -gi _unixcfg_local_overrides_loaded=0
      _unixcfg_prompt_screen_prefix() {
        if [[ -n "''${STY:-}" ]]; then
          echo "%F{magenta}[screen]%f "
        fi
      }
      _unixcfg_prompt_apply_screen_prefix() {
        local prefix="$(_unixcfg_prompt_screen_prefix)"

        if [[ -z "$prefix" ]]; then
          if [[ -n "''${UNIXCFG_PROMPT_BASE:-}" ]]; then
            PROMPT="$UNIXCFG_PROMPT_BASE"
          fi
          return 0
        fi

        if [[ -z "''${UNIXCFG_PROMPT_BASE:-}" ]]; then
          UNIXCFG_PROMPT_BASE="$PROMPT"
        fi
        PROMPT="''${prefix}''${UNIXCFG_PROMPT_BASE}"
      }
      # Backward compatibility for stale precmd hooks from previous shell setups.
      _dotfiles_prompt_screen_prefix() {
        _unixcfg_prompt_screen_prefix "$@"
      }
      _dotfiles_prompt_apply_screen_prefix() {
        _unixcfg_prompt_apply_screen_prefix "$@"
      }
      _unixcfg_load_local_shell_overrides() {
        (( _unixcfg_local_overrides_loaded )) && return
        _unixcfg_local_overrides_loaded=1

        local local_aliases="''${ZDOTDIR:-$HOME}/.zsh_aliases"
        [[ -r "$local_aliases" ]] && source "$local_aliases"

        local local_functions="''${ZDOTDIR:-$HOME}/.zsh_functions"
        [[ -r "$local_functions" ]] && source "$local_functions"
      }

      autoload -Uz add-zsh-hook
      add-zsh-hook precmd _unixcfg_load_local_shell_overrides
      precmd_functions=( ''${precmd_functions:#_dotfiles_prompt_apply_screen_prefix} )
      if ! (( ''${precmd_functions[(Ie)_unixcfg_prompt_apply_screen_prefix]} )); then
        add-zsh-hook precmd _unixcfg_prompt_apply_screen_prefix
      fi
    '';
    oh-my-zsh = {
      enable = false;
    };
    shellAliases = {
      rm = "rm -I";
      hmtest = "echo HOME_MANAGER_IS_WORKING";

      ll = "ls -alF";
      la = "ls -A";
      l = "ls -CF";

      cp = "cp -r -v";
      mv = "mv -v";
      less = "less -N";

      www = "cd /var/www";
      dots = "cd $UNIXCFG_REPO";
      tmux = "tmux-auto";
      ugx = "chmod ug+x";
      gr = "git_root";
    };
    sessionVariables = editorEnv // {
      UNIXCFG_REPO = "${config.home.homeDirectory}/git/github.com/jakestanley/nix";
    };
  };
}
