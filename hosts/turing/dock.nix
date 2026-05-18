{ ... }:

let
  dockFolderBase = "/Users/jake/Desktop/Dock Folders";

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

  mkNamedFolder = { name, showas ? "automatic" }:
    mkDockFolder { path = "${dockFolderBase}/${name}"; inherit showas; };
in
{
  system.defaults.dock = {
    autohide = false;
    mru-spaces = false;
    show-recents = false;
    tilesize = 50;
    magnification = false;

    persistent-apps = [
      { app = "/System/Applications/Calendar.app"; }
      { app = "/Applications/1Password.app"; }
      { app = "/Applications/Nix Apps/Firefox.app"; }
      { app = "/Applications/Spotify.app"; }
      { app = "/Applications/WhatsApp.app"; }
      { app = "/Applications/Nix Apps/Telegram.app"; }
      { app = "/System/Applications/Mail.app"; }
      { app = "/Applications/Numbers Creator Studio.app"; }
      { app = "/Applications/Obsidian.app"; }
      { app = "/Applications/Nix Apps/Visual Studio Code.app"; }
      { app = "/Applications/Claude.app"; }
      { app = "/Applications/Ableton Live 11 Standard.app"; }
      { app = "/System/Applications/iPhone Mirroring.app"; }
      { app = "/System/Applications/Utilities/Terminal.app"; }
      { app = "/System/Applications/System Settings.app"; }
    ];

    persistent-others =
      (map mkNamedFolder [
        { name = "Music";       showas = "fan"; }
        { name = "Games";       showas = "automatic"; }
        { name = "Development"; showas = "fan"; }
        { name = "Work";        showas = "fan"; }
      ])
      ++ [
        (mkDockFolder {
          path = "/Users/jake/Downloads";
          arrangement = "date-added";
          displayas = "folder";
          showas = "grid";
        })
      ];
  };
}
