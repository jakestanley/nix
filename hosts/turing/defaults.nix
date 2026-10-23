{ config, ... }:

let
  user = config.system.primaryUser;
in
{
  # Free up Cmd+Space for Raycast by disabling the Spotlight search shortcut (symbolic hotkey 64).
  # Uses -dict-add rather than CustomUserPreferences, which would replace the whole
  # AppleSymbolicHotKeys dict and wipe every other system shortcut.
  system.activationScripts.postActivation.text = ''
    sudo -u ${user} defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 \
      '<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>49</integer><integer>1048576</integer></array><key>type</key><string>standard</string></dict></dict>'
    sudo -u ${user} /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';

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

