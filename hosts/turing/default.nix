{ pkgs, inputs, dockProfile ? "personal", ... }:

let
  mkDockFolder = {
    path,
    arrangement ? "name",
    displayas ? "stack",
    showas ? "automatic"
  }: {
    folder = {
      inherit path arrangement displayas showas;
    };
  };

  dockCommon = {
    autohide = false;
    mru-spaces = false;
    show-recents = false;
    tilesize = 50;
    magnification = false;
  };

  dockCommonAppsHead = [
    { app = "/System/Applications/Calendar.app"; }
    { app = "/Applications/1Password.app"; }
    { app = "/Applications/Safari.app"; }
    { app = "/Applications/Spotify.app"; }
  ];

  dockCommonAppsCenter = [
    { app = "/Applications/Obsidian.app"; }
    { app = "/Applications/Visual Studio Code.app"; }
    { app = "/Applications/ChatGPT.app"; }
    { app = "/Applications/Claude.app"; }
  ];

  dockCommonAppsTail = [
    { app = "/System/Applications/Utilities/Terminal.app"; }
    { app = "/System/Applications/Utilities/Activity Monitor.app"; }
    { app = "/System/Applications/System Settings.app"; }
  ];

  dockPersonalApps =
    dockCommonAppsHead
    ++ [
      { app = "/Applications/WhatsApp.app"; }
      { app = "/System/Applications/Messages.app"; }
      { app = "/Applications/Numbers Creator Studio.app"; }
      { app = "/System/Applications/Mail.app"; }
    ]
    ++ dockCommonAppsCenter
    ++ [
      { app = "/Applications/Ableton Live 11 Standard.app"; }
      { app = "/Applications/Mixed In Key 11.app"; }
      { app = "/Applications/Guitar Pro 8.app"; }
      { app = "/Applications/Flight Deck.app"; }
      { app = "/System/Applications/Music.app"; }
      { app = "/Applications/Discord.app"; }
      { app = "/Applications/Windows App.app"; }
      { app = "/Applications/Tunnelblick.app"; }
      { app = "/System/Applications/iPhone Mirroring.app"; }
    ]
    ++ dockCommonAppsTail;

  dockWorkApps =
    dockCommonAppsHead
    ++ [
      { app = "/Applications/WorkSpaces.app"; }
      { app = "/Applications/Google Chrome.app"; }
      { app = "/Applications/Microsoft Teams.app"; }
      { app = "/Applications/Microsoft Outlook.app"; }
    ]
    ++ dockCommonAppsCenter
    ++ dockCommonAppsTail;

  dockCommonOthers = [
    (mkDockFolder {
      path = "/Users/jake/Downloads";
      arrangement = "date-added";
      displayas = "folder";
      showas = "grid";
    })
  ];

  dockPersonalOthers = [
    (mkDockFolder {
      path = "/Users/jake/Desktop/Dock Folders/Music";
      showas = "fan";
    })
    (mkDockFolder {
      path = "/Users/jake/Desktop/Dock Folders/Games";
      showas = "automatic";
    })
    (mkDockFolder {
      path = "/Users/jake/Desktop/Dock Folders/Development";
      showas = "fan";
    })
  ] ++ dockCommonOthers;

  dockWorkOthers = [
    (mkDockFolder {
      path = "/Users/jake/Desktop/Dock Folders/Work";
      showas = "fan";
    })
  ] ++ dockCommonOthers;

  dockProfileOverrides = if dockProfile == "personal" then {
    persistent-apps = dockPersonalApps;
    persistent-others = dockPersonalOthers;
  } else if dockProfile == "work" then {
    persistent-apps = dockWorkApps;
    persistent-others = dockWorkOthers;
  } else
    throw "Unsupported turing dockProfile '${dockProfile}'. Expected 'personal' or 'work'.";
in
{
  networking.hostName = "turing";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.jake = {
    home = "/Users/jake";
    shell = pkgs.zsh;
  };
  system.primaryUser = "jake";

  programs.zsh.enable = true;

  environment.systemPackages = [
    pkgs.vim
    inputs.cherri.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # Adopt Homebrew declaratively without removing unmanaged packages yet.
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = false;
      cleanup = "uninstall";
    };

    brews = [
      "abseil"
      "gnu-sed"
      "libpq"
      "openexr"
      "raylib"
      "act"
      "gnupg"
      "libpthread-stubs"
      "openjdk"
      "rclone"
      "ada-url"
      "gnutls"
      "libraw"
      "openjpeg"
      "readline"
      "aom"
      "go"
      "libsamplerate"
      "openjph"
      "redis"
      "appstream-glib"
      "gobject-introspection"
      "libslirp"
      "openrct2"
      "ripgrep"
      "apr"
      "googletest"
      "libsndfile"
      "openssl@3"
      "rom-tools"
      "apr-util"
      "graphite2"
      "libssh2"
      "openvpn"
      "rubberband"
      "argtable"
      "gtk-doc"
      "libtasn1"
      "opus"
      "rust"
      "arp-scan"
      "gumbo-parser"
      "libthai"
      "opusfile"
      "sdl12-compat"
      "assimp"
      "handbrake"
      "libtiff"
      "p11-kit"
      "sdl2"
      "at-spi2-core"
      "harfbuzz"
      "libtommath"
      "pandoc"
      "sdl2_gfx"
      "atk"
      "hdrhistogram_c"
      "libtool"
      "pango"
      "sdl2_image"
      "autoconf"
      "highway"
      "libudfread"
      "pcre2"
      "sdl2_mixer"
      "automake"
      "htop"
      "libunibreak"
      "pinentry"
      "sdl2_net"
      "aws-cdk"
      "hunspell"
      "libunistring"
      "pinentry-mac"
      "sdl2_sound"
      "awscli"
      "icu4c@76"
      "libusb"
      "pipx"
      "sdl2_ttf"
      "bash"
      "icu4c@77"
      "libuv"
      "pixman"
      "sdl_gfx"
      "bfg"
      "icu4c@78"
      "libvmaf"
      "pkcs11-helper"
      "sevenzip"
      "boost"
      "id3lib"
      "libvorbis"
      "pkgconf"
      "sfml"
      "brotli"
      "id3v2"
      "libvpx"
      "pnpm"
      "shaderc"
      "c-ares"
      "imagemagick"
      "libx11"
      "popt"
      "shared-mime-info"
      "ca-certificates"
      "imath"
      "libxau"
      "portaudio"
      "shellcheck"
      "cairo"
      "imlib2"
      "libxcb"
      "portmidi"
      "simdjson"
      "certifi"
      "innoextract"
      "libxdmcp"
      "protobuf"
      "speedtest-cli"
      "chocolate-doom"
      "itstool"
      "libxext"
      "py3cairo"
      "speex"
      "cmake"
      "jansson"
      "libxfixes"
      "pycparser"
      "sqlite"
      "cmatrix"
      "jasper"
      "libxi"
      "pyenv"
      "stoken"
      "coin3d"
      "jbig2dec"
      "libxml2"
      "pygobject3"
      "subversion"
      "coreutils"
      "jpeg-turbo"
      "libxmp"
      "python-certifi"
      "svt-av1"
      "crispy-doom"
      "jpeg-xl"
      "libxrender"
      "python-packaging"
      "tcl-tk"
      "curl"
      "jq"
      "libxslt"
      "python-tk@3.12"
      "telnet"
      "cython"
      "json-c"
      "libxtst"
      "python@3.12"
      "tesseract"
      "dav1d"
      "json-glib"
      "libyaml"
      "python@3.13"
      "theora"
      "dbus"
      "judy"
      "libzip"
      "python@3.14"
      "tldr"
      "deno"
      "krb5"
      "litehtml"
      "python@3.8"
      "tmux"
      "desktop-file-utils"
      "lame"
      "little-cms2"
      "python@3.9"
      "toilet"
      "displayplacer"
      "leptonica"
      "llama.cpp"
      "qt"
      "tree"
      "dnsmasq"
      "libao"
      "llhttp"
      "qt3d"
      "tree-sitter@0.25"
      "docbook"
      "libarchive"
      "llvm"
      "qt5compat"
      "uchardet"
      "docbook-xsl"
      "libass"
      "lpeg"
      "qt@5"
      "unbound"
      "docker"
      "libassuan"
      "lua"
      "qtbase"
      "unibilium"
      "docker-buildx"
      "libavif"
      "luajit"
      "qtcharts"
      "utf8proc"
      "docker-completion"
      "libb2"
      "luv"
      "qtconnectivity"
      "uvwasi"
      "docker-compose"
      "libbluray"
      "lz4"
      "qtdatavis3d"
      "vapoursynth"
      "docker-credential-helper"
      "libcaca"
      "lzo"
      "qtdeclarative"
      "vcdimager"
      "docutils"
      "libcdio"
      "m4"
      "qtgraphs"
      "vgmstream"
      "dos2unix"
      "libdatrie"
      "mad"
      "qtgrpc"
      "vpn-slice"
      "dosbox-x"
      "libde265"
      "md4c"
      "qthttpserver"
      "vulkan-headers"
      "dotnet"
      "libdeflate"
      "meson"
      "qtimageformats"
      "vulkan-loader"
      "double-conversion"
      "libdnet"
      "mlx"
      "qtlanguageserver"
      "watch"
      "dsda-doom"
      "libdvdcss"
      "mlx-c"
      "qtlocation"
      "wavpack"
      "duf"
      "libdvdnav"
      "molten-vk"
      "qtlottie"
      "webp"
      "dumb"
      "libdvdread"
      "mono"
      "qtmultimedia"
      "wget"
      "dylibbundler"
      "libevent"
      "mono-libgdiplus"
      "qtnetworkauth"
      "whatscli"
      "flac"
      "libexif"
      "mosh"
      "qtpositioning"
      "wireguard-go"
      "fluid-synth"
      "libffi"
      "mpdecimal"
      "qtquick3d"
      "wireguard-tools"
      "fmt"
      "libgcrypt"
      "mpg123"
      "qtquick3dphysics"
      "wla-dx"
      "fontconfig"
      "libgit2"
      "mplayer"
      "qtquickeffectmaker"
      "wxwidgets"
      "freeimage"
      "libgpg-error"
      "mpv"
      "qtquicktimeline"
      "x264"
      "freetype"
      "libheif"
      "mujs"
      "qtremoteobjects"
      "x265"
      "fribidi"
      "libidn"
      "nasm"
      "qtscxml"
      "xorgproto"
      "ftgl"
      "libidn2"
      "ncdu"
      "qtsensors"
      "xq"
      "game-music-emu"
      "libksba"
      "ncurses"
      "qtserialbus"
      "xz"
      "gdbm"
      "liblinear"
      "neovim"
      "qtserialport"
      "yaml-cpp"
      "gdk-pixbuf"
      "liblqr"
      "nethack"
      "qtshadertools"
      "yq"
      "gettext"
      "libmicrohttpd"
      "nettle"
      "qtspeech"
      "yt-dlp"
      "ghostscript"
      "libmng"
      "ninja"
      "qtsvg"
      "z3"
      "giflib"
      "libnghttp2"
      "nmap"
      "qttools"
      "zbar"
      "gifsicle"
      "libnghttp3"
      "node"
      "qttranslations"
      "zimg"
      "git-filter-repo"
      "libngtcp2"
      "npth"
      "qtvirtualkeyboard"
      "zlib"
      "glew"
      "libogg"
      "ollama"
      "qtwebchannel"
      "zmap"
      "glfw"
      "libomp"
      "oniguruma"
      "qtwebengine"
      "zstd"
      "glib"
      "libplacebo"
      "openal-soft"
      "qtwebsockets"
      "gmp"
      "libpng"
      "openconnect"
      "qtwebview"
    ];

    # Starter set for desktop app management; expand incrementally.
    casks = [
      "ableton-live-standard@11"
      "discord"
      "guitar-pro"
      "minecraft"
      "qlab"
      "mixed-in-key"
      "rar"
      "audacity"
      "moonlight"
      "spotify"
      "autodesk-fusion"
      "hex-fiend"
      "mp3tag"
      "steam"
      "balenaetcher"
      "exfalso"
      "inkscape"
      "steamcmd"
      "bambu-studio"
      "firefox"
      "itch"
      "jetbrains-toolbox"
      "obs"
      "tunnelblick"
      "blender"
      "font-ubuntu-mono"
      "font-ubuntu-mono-nerd-font"
      "obsidian"
      "visual-studio-code"
      "caffeine"
      "macs-fan-control"
      "omnidisksweeper"
      "vlc"
      "chatgpt"
      "godot"
      "postman"
      "claude"
      "gog-galaxy"
      "powershell"
      "diffmerge"
      "google-chrome"
      "microsoft-teams"
      "prismlauncher"
      "dropbox"
      "1password"
      "cyberduck"
      #"devilutionx"
      "duplicate-file-finder"
      "energiza"
      #"godot@3"
      "istatistica-core"
      "ledger-wallet"
      "logitech-g-hub"
      "microsoft-excel"
      "microsoft-outlook"
      "microsoft-powerpoint"
      "microsoft-word"
      "upscayl"
      # "virtualbox"
      "whatsapp"
      "windows-app"
      "amazon-workspaces"
      "zoom"
    ];
  };

  security.sudo.extraConfig = ''
    Cmnd_Alias TUNING_DOCK_SWITCH = \
      /Users/jake/git/github.com/jakestanley/nixos-shrike/scripts/switch-turing-dock.sh work, \
      /Users/jake/git/github.com/jakestanley/nixos-shrike/scripts/switch-turing-dock.sh personal
    jake ALL=(root) NOPASSWD: TUNING_DOCK_SWITCH
  '';

  system.defaults = {
    dock = dockCommon // dockProfileOverrides;

    finder = {
      AppleShowAllExtensions = false;
      FXEnableExtensionChangeWarning = true;
      FXPreferredViewStyle = "Nlsv";
      ShowPathbar = false;
      ShowStatusBar = true;
    };

    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = false;
    };

    screencapture = {
      disable-shadow = false;
      location = "/Users/jake/Desktop";
      type = "png";
    };

    NSGlobalDomain = {
      NSAutomaticCapitalizationEnabled = true;
      NSAutomaticDashSubstitutionEnabled = true;
      NSAutomaticPeriodSubstitutionEnabled = true;
      NSAutomaticQuoteSubstitutionEnabled = true;
      NSAutomaticSpellingCorrectionEnabled = true;
    };
  };

  system.stateVersion = 6;
}
