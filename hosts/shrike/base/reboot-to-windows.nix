{ pkgs, lib, ... }:

let
    windowsIcon = pkgs.fetchurl {
        url = "https://upload.wikimedia.org/wikipedia/commons/6/6a/Windows_logo_-_2021_%28White%29.svg";
        sha256 = "sha256-qKGIcHWrvefuIZaiq4GrzisvWAoSpFrYbHl/mP1IxdM=";
    };

    rebootToWindows = pkgs.writeShellScriptBin "reboot-to-windows" ''
        set -euo pipefail

        # GUI confirm (prefer kdialog, then zenity). If neither exists, refuse.
        confirm() {
        local msg="Reboot into Windows now?"
        if command -v kdialog >/dev/null 2>&1; then
            kdialog --title "Reboot to Windows" --warningyesno "$msg"
            return $?
        fi
        if command -v zenity >/dev/null 2>&1; then
            zenity --question --title="Reboot to Windows" --text="$msg"
            return $?
        fi
        if command -v notify-send >/dev/null 2>&1; then
            notify-send "Reboot to Windows" "Install kdialog or zenity for confirmation prompts."
        fi
        echo "ERROR: Need kdialog or zenity for a Yes/No popup." >&2
        return 2
        }

        confirm || exit 0

        # Need root for efibootmgr + reboot.
        # Prefer pkexec if available (nice GUI auth), otherwise sudo.
        run_root() {
        if command -v pkexec >/dev/null 2>&1; then
            pkexec "$@"
        else
            sudo "$@"
        fi
        }

        run_root ${pkgs.efibootmgr}/bin/efibootmgr -n 0000
        run_root ${pkgs.systemd}/bin/reboot
    '';

    desktopItem = pkgs.makeDesktopItem {
        name = "reboot-to-windows";
        desktopName = "Reboot to Windows";
        comment = "Reboot directly into Windows";
        exec = "reboot-to-windows";
        icon = "windows";
        categories = [ "System" ];
        terminal = false;
    };

    windowsIconPkg = pkgs.runCommand "windows-icon" {} ''
        mkdir -p $out/share/icons/hicolor/scalable/apps
        cp ${windowsIcon} $out/share/icons/hicolor/scalable/apps/windows.svg
    '';
in
{
    environment.systemPackages = [
        rebootToWindows
        desktopItem
        windowsIconPkg
    ];
}
