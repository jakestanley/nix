{ config, lib, ... }:

let
  editorEnv = import ../../../modules/shared/editor-env.nix;
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

  programs.zsh = {
    autocd = false;
    history = {
      append = true;
      ignoreAllDups = true;
    };
    setOptions = [
      "HIST_REDUCE_BLANKS"
      "HIST_FIND_NO_DUPS"
    ];

    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    siteFunctions = {
      # docker ssh. requires docker and jq
      docker_ssh = ''
        if [[ "$2" != "" ]]; then
          PORT_EXT="-p $2"
        fi
        ssh root@$(docker inspect $1 | jq '.[0].NetworkSettings.Networks.bridge.IPAddress' --raw-output) ''${PORT_EXT}
      '';

      # bash from within a docker instance. just pass the docker image name. very basic
      docker_bash = ''
        docker run -it --entrypoint /bin/bash $1
      '';

      git_root = ''
        cd $(git rev-parse --show-toplevel)
      '';

      # gets container name and image of all running instances
      derps = ''
        watch "docker ps --format \"{{.Names}}: {{.Image}}\""
      '';

      gitignore = ''
        echo "Generating a .gitignore file in the current directory."

        curl https://raw.githubusercontent.com/github/gitignore/master/Java.gitignore >> ./.gitignore
        curl https://raw.githubusercontent.com/github/gitignore/master/Global/JetBrains.gitignore >> ./.gitignore

        echo -e "# More JetBrains crap" >> ./.gitignore
        echo -e "*.iml\n*.ipr" >> ./.gitignore

        echo -e "# Sublime Text" >> ./.gitignore
        echo -e "*sublime-*" >> ./.gitignore

        echo -e "# Vim" >> ./.gitignore
        echo -e "*.swp" >> ./.gitignore
      '';

      pip_install = ''
        python -m pip install -U $1 --user
      '';

      # adapted from: https://dhoeric.github.io/2017/https-to-ssh-in-gitmodules
      git_origin_to_https = ''
        OLD_URL=$(git remote get-url origin)
        if [[ $(echo $OLD_URL | grep -c ^https) == 1 ]]; then
          echo "origin is already pointing to https: '$OLD_URL'"
          return
        fi
        NEW_URL=$(echo $OLD_URL | perl -p -e 's|git@(.*?):|https://\1/|g')
        git remote set-url origin $NEW_URL
      '';

      # adapted from: https://dhoeric.github.io/2017/https-to-ssh-in-gitmodules
      git_origin_to_ssh = ''
        OLD_URL=$(git remote get-url origin)
        if [[ $(echo $OLD_URL | grep -c ^https) == 0 ]]; then
          echo "origin does not appear to already be using https: '$OLD_URL'"
          return
        fi
        NEW_URL=$(echo $OLD_URL | perl -p -e 's|https://(.*?)/|git@\1:|g')
        git remote set-url origin $NEW_URL
      '';

      dots = ''
        cd "''${UNIXCFG_REPO:-$HOME/git/github.com/jakestanley/nix}"
      '';

      # Prompt helpers
      _dotfiles_prompt_screen_prefix = ''
        if [[ -n "''${STY:-}" ]]; then
          echo "%F{magenta}[screen]%f "
        fi
      '';

      _dotfiles_prompt_apply_screen_prefix = ''
        local prefix="$(_dotfiles_prompt_screen_prefix)"

        if [[ -z "$prefix" ]]; then
          if [[ -n "''${DOTFILES_PROMPT_BASE:-}" ]]; then
            PROMPT="$DOTFILES_PROMPT_BASE"
          fi
          return 0
        fi

        if [[ -z "''${DOTFILES_PROMPT_BASE:-}" ]]; then
          DOTFILES_PROMPT_BASE="$PROMPT"
        fi
        PROMPT="''${prefix}''${DOTFILES_PROMPT_BASE}"
      '';

      git_amend_add_8h = ''
        local hours="''${1:-8}"

        if ! [[ "$hours" =~ '^-?[0-9]+$' ]]; then
          echo "usage: git_amend_add_8h [hours]  (default: 8)" >&2
          return 2
        fi

        if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
          echo "not inside a git repository" >&2
          return 1
        fi

        if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
          echo "no commits found (HEAD does not exist)" >&2
          return 1
        fi

        if ! command -v python3 >/dev/null 2>&1; then
          echo "python3 is required to adjust timestamps" >&2
          return 1
        fi

        local author_date
        local committer_date
        local new_author_date
        local new_committer_date

        author_date=$(git show -s --format=%aI HEAD) || return 1
        committer_date=$(git show -s --format=%cI HEAD) || return 1

        new_author_date=$(
          python3 - "$author_date" "$hours" <<'PY'
        import sys
        from datetime import datetime, timedelta

        value = sys.argv[1].replace("Z", "+00:00")
        hours = int(sys.argv[2])
        dt = datetime.fromisoformat(value)
        print((dt + timedelta(hours=hours)).isoformat())
        PY
        ) || return 1

        new_committer_date=$(
          python3 - "$committer_date" "$hours" <<'PY'
        import sys
        from datetime import datetime, timedelta

        value = sys.argv[1].replace("Z", "+00:00")
        hours = int(sys.argv[2])
        dt = datetime.fromisoformat(value)
        print((dt + timedelta(hours=hours)).isoformat())
        PY
        ) || return 1

        echo "Amending HEAD: shift timestamps by ''${hours}h"
        echo "Author:    ''${author_date} -> ''${new_author_date}"
        echo "Committer: ''${committer_date} -> ''${new_committer_date}"

        GIT_COMMITTER_DATE="$new_committer_date" \
          git commit --amend --no-edit --date "$new_author_date"
      '';

      "buildkit-clean" = ''
        export DOCKER_BUILDKIT=1
        docker stop buildx_buildkit_maven0 \
          && docker rm buildx_buildkit_maven0 \
          && docker rmi moby/buildkit:buildx-stable-1
        docker buildx rm maven
        docker builder rm maven
      '';

      "demucs-sync" = ''
        rsync -av --delete --prune-empty-dirs \
          --exclude='._*' \
          --include='/reports/***' \
          --include='/Playlists/' \
          --include='/Playlists/**/' \
          --include='/Playlists/**/unprocessed/***' \
          --exclude='*' \
          jake@adler:~/Music/ \
          ~/Music/
      '';
    };
    initContent = ''
      bindkey '^R' history-incremental-search-backward
      typeset -gaU FZF_IGNORE_PATTERNS
      FZF_IGNORE_PATTERNS+=( '*.class' )

      # Load local alias/function overrides after HM shellAliases so local,
      # untracked work aliases can override tracked defaults when needed.
      typeset -gi _unixcfg_local_overrides_loaded=0
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
      if ! (( ''${precmd_functions[(Ie)_dotfiles_prompt_apply_screen_prefix]} )); then
        add-zsh-hook precmd _dotfiles_prompt_apply_screen_prefix
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
      tmux = "$UNIXCFG_REPO/scripts/tmux-auto.sh";
      rfcdate = "date --rfc-3339=date";
      ugx = "chmod ug+x";
      gr = "git_root";
    };
    sessionVariables = editorEnv // {
      UNIXCFG_REPO = "${config.home.homeDirectory}/git/github.com/jakestanley/nix";
    };
  };
}
