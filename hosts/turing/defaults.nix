{ ... }:

{
  system.defaults = {
    CustomUserPreferences."com.apple.desktopservices" = {
      # Prevent Finder from writing .DS_Store to network and USB/external volumes.
      DSDontWriteNetworkStores = true;
      DSDontWriteUSBStores = true;
    };

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
}

