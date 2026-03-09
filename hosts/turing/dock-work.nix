{ lib, ... }:

{
  system.defaults.dock = {
    persistent-apps = lib.mkForce [
      { app = "/System/Applications/Calendar.app"; }
      { app = "/Applications/1Password.app"; }
      { app = "/System/Applications/Messages.app"; }
      { app = "/Applications/Google Chrome.app"; }
      { app = "/Applications/Microsoft Teams.app"; }
      { app = "/Applications/Microsoft Outlook.app"; }
      { app = "/Applications/Microsoft Word.app"; }
      { app = "/Applications/Microsoft Excel.app"; }
      { app = "/Applications/Microsoft PowerPoint.app"; }
      { app = "/Applications/Obsidian.app"; }
      { app = "/Applications/Visual Studio Code.app"; }
      { app = "/Applications/ChatGPT.app"; }
      { app = "/Applications/Claude.app"; }
      { app = "/Applications/Windows App.app"; }
      { app = "/Applications/Tunnelblick.app"; }
      { app = "/System/Applications/Utilities/Terminal.app"; }
      { app = "/System/Applications/Utilities/Activity Monitor.app"; }
      { app = "/System/Applications/System Settings.app"; }
    ];

    persistent-others = lib.mkForce [
      {
        folder = {
          path = "/Users/jake/Desktop/Dock Folders/Work";
          arrangement = "name";
          displayas = "stack";
          showas = "fan";
        };
      }
      {
        folder = {
          path = "/Users/jake/Downloads";
          arrangement = "date-added";
          displayas = "folder";
          showas = "grid";
        };
      }
    ];
  };
}
