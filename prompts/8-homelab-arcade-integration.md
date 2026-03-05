I can't remember why pyqt6 is there; it's web based basically so if it's not needed we can remove it.

You install the service, install games from Steam in user mode outside of nix (accepted decision, games are basically data, not applications) and then tell using the config where your game install is, although this could be data that is configured as state rather than at install time, removing the dependency. We're not looking for the game server to run out of the box, just the code that manages it.

If no further clarifications are needed, let's hear the prompt 