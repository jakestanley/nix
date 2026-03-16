{
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
    cd "$UNIXCFG_REPO"
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
      jake@adler.stanley.arpa:~/Music/ \
      ~/Music/
  '';
}
