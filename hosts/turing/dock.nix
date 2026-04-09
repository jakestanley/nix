{ dockProfile ? "personal", ... }:

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
    { app = "/Applications/WhatsApp.app"; }
  ];

  dockCommonAppsCenter = [
    { app = "/Applications/Obsidian.app"; }
    { app = "/Applications/Visual Studio Code.app"; }
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
      # { app = "/Applications/Windows App.app"; }
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
  system.defaults.dock = dockCommon // dockProfileOverrides;
}

