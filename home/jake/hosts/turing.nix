{ config, lib, ... }:

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

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "find . -type d \\( -name .git -o -name node_modules \\) -prune -o -type f -print 2>/dev/null";
    fileWidgetCommand = "find . -type d \\( -name .git -o -name node_modules \\) -prune -o -type f -print 2>/dev/null";
    changeDirWidgetCommand = "find . -type d \\( -name .git -o -name node_modules \\) -prune -o -type d -print 2>/dev/null";
  };

  programs.zsh = {
    autocd = false;
    history = {
      append = true;
      ignoreAllDups = true;
    };
    setOptions = [ "HIST_REDUCE_BLANKS" ];

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

      # create a new sublime project for this directory (or argument) or open
      # a project if one exists there
      stn = ''
        local target=$1

        if [[ "''${target}" == "" ]]; then
          target=$(pwd)
        elif [[ ! -d ''${target} ]]; then
          echo "''${target} is not a valid directory"
          return 1
        fi

        local sublime_project_file=$target/$(basename $target).sublime-project

        if [[ ! -f $sublime_project_file ]]; then
          touch $sublime_project_file

          echo -e "{" >> $sublime_project_file
          echo -e "\t\"folders\":" >> $sublime_project_file
          echo -e "\t\t[{" >> $sublime_project_file
          echo -e "\t\t\t\"path\": \".\"," >> $sublime_project_file
          echo -e "\t\t\t\"file_exclude_patterns\": []" >> $sublime_project_file
          echo -e "\t\t}]" >> $sublime_project_file
          echo -e "}" >> $sublime_project_file

          echo -e "New Sublime Text project created:\n\t''${sublime_project_file}"
        fi
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

    oh-my-zsh = {
      enable = lib.mkForce true;
      theme = "robbyrussell";
      plugins = [
        "git"
        "docker"
      ];
    };

    shellAliases = {
      python = "python3";
      mysql = "mysql --defaults-extra-file=~/.mycredentials.cnf";
      mysqldump = "mysqldump --defaults-extra-file=~/.mycredentials.cnf";
      got = "git";
      gitc = "git-cola";
      maven = "mvn";
      mcv = "mvn clean verify";
      cbcp = "xclip -selection clip-board -rmlastnl";

      nginxerrors = "\less +F /var/log/nginx/error.log";
      www = "cd /var/www";
      fortunecow = "watch -n 3600 \"fortune -s | cowsay\"";
      dots = "cd $UNIXCFG_REPO";
      tmux = "$UNIXCFG_REPO/scripts/tmux-auto.sh";

      cp = "cp -r -v";
      mv = "mv -v";
      less = "less -N";
      lesss = "less -N";
      les = "less -N";
      ".." = "cd ..";
      "..2" = "cd ../..";
      "..3" = "cd ../../..";
      "..4" = "cd ../../../..";
      "..5" = "cd ../../../../..";
      "..6" = "cd ../../../../../..";

      ll = "ls -alF";
      la = "ls -A";
      l = "ls -CF";

      destroy = "rm -rf";
      cf = "aws cloudformation --region eu-west-1";
      dicker = "docker";
      dc = "docker-compose";
      sf = "screenfetch";
      rfcdate = "date --rfc-3339=date";

      ugx = "chmod ug+x";
      list = "ls -l | grep --color=none -o \"[^[:space:]]*$\"";
      gr = "git_root";
      fetch = "git fetch --all";

      mp3-ytdl = "youtube-dl --extract-audio --audio-format mp3";
      wav-ytdl = "youtube-dl --extract-audio --audio-format wav";
      yda = "youtube-dl -o \"$(date +%F_%H-%M-%S).%(ext)s\"";

      gh = "cd $HOME/git/github.com || mkdir -p $HOME/git/github.com";
    };

    # Keep this host-specific until explicitly promoted into common shell.nix.
    initContent = lib.mkBefore ''
      UNIXCFG_REPO="''${UNIXCFG_REPO:-$HOME/git/github.com/jakestanley/nix}"

      # Register host-specific autoloadable functions.
      autoload -Uz \
        docker_ssh \
        docker_bash \
        git_root \
        derps \
        gitignore \
        pip_install \
        stn \
        git_origin_to_https \
        git_origin_to_ssh \
        dots \
        _dotfiles_prompt_screen_prefix \
        _dotfiles_prompt_apply_screen_prefix \
        git_amend_add_8h \
        buildkit-clean \
        demucs-sync

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
