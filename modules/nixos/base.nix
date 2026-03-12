{ inputs, pkgs, ... }:

let
  editorEnv = import ../shared/editor-env.nix;
  flakeSelf = inputs.self;
  configurationRevision =
    if flakeSelf ? dirtyShortRev && flakeSelf.dirtyShortRev != null then flakeSelf.dirtyShortRev
    else if flakeSelf ? shortRev && flakeSelf.shortRev != null then flakeSelf.shortRev
    else null;
in

{
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/London";

  i18n.defaultLocale = "en_GB.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  console.keyMap = "uk";

  services.printing.enable = false;

  users.users.jake = {
    isNormalUser = true;
    description = "Jake Stanley";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };

  services.logind.settings.Login = {
    IdleAction = "ignore";
    IdleActionSec = "0";
  };

  programs.zsh.enable = true;

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.configurationRevision = configurationRevision;

  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    screen
    ripgrep
    ethtool
    fastfetch
    efibootmgr
    dig
  ];

  environment.variables = editorEnv;
}
