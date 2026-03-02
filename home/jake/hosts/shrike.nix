{ config, inputs, lib, pkgs, ... }:

let
  qfont = import "${inputs.plasma-manager}/lib/qfont.nix" { inherit lib; };
  kateHack10 = qfont.fontToString {
    family = "Hack";
    pointSize = 10;
  };
  konsoleUbuntuMono = qfont.fontToString {
    family = "Ubuntu Mono";
    pointSize = 11;
    styleHint = "monospace";
    fixedPitch = true;
    styleStrategy.antialiasing = "disable";
  };
  konsoleProfileName = "Shrike";
  displaySync = pkgs.writeTextFile {
    name = "display-sync";
    destination = "/bin/display-sync";
    executable = true;
    text = ''
      #!${pkgs.python3}/bin/python3

      from __future__ import annotations

      import json
      import os
      import subprocess
      import sys
      import time
      from datetime import datetime

      DEBUG = os.environ.get("DISPLAY_SYNC_DEBUG") == "1"
      POLL_SECONDS = 3


      def log_debug(message: str) -> None:
          if DEBUG:
              timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
              print(f"[display-sync] {timestamp} {message}", file=sys.stderr, flush=True)


      def parse_embedded_json(text: str):
          decoder = json.JSONDecoder()
          for marker in ("{", "["):
              start = text.find(marker)
              while start != -1:
                  try:
                      payload, _ = decoder.raw_decode(text[start:])
                      if isinstance(payload, (dict, list)):
                          return payload
                  except json.JSONDecodeError:
                      pass
                  start = text.find(marker, start + 1)
          return None


      def run_kscreen_json():
          commands = (["kscreen-doctor", "--json", "-o"], ["kscreen-doctor", "-j", "-o"])
          for command in commands:
              try:
                  completed = subprocess.run(
                      command,
                      capture_output=True,
                      text=True,
                      check=False,
                  )
                  payload = parse_embedded_json(completed.stdout)
                  if payload is None and completed.stderr:
                      payload = parse_embedded_json(completed.stderr)
                  if payload is not None:
                      return payload
                  if DEBUG:
                      log_debug(f"no JSON payload found ({' '.join(command)})")
              except Exception as exc:
                  if DEBUG:
                      log_debug(f"query failed ({' '.join(command)}): {exc}")
          return None


      def get_outputs():
          payload = run_kscreen_json()
          if payload is None:
              return []

          outputs = payload.get("outputs", []) if isinstance(payload, dict) else payload
          return outputs if isinstance(outputs, list) else []


      def is_primary_enabled(outputs) -> bool:
          for output in outputs:
              if not isinstance(output, dict):
                  continue
              name = output.get("name")
              if isinstance(name, str) and name.startswith("DP-") and output.get("enabled"):
                  return True
          return False


      def set_dummy_enabled(outputs, enable: bool) -> None:
          action = "enable" if enable else "disable"
          for output in outputs:
              if not isinstance(output, dict):
                  continue
              name = output.get("name")
              if not (isinstance(name, str) and name.startswith("HDMI-")):
                  continue

              command = ["kscreen-doctor", f"output.{name}.{action}"]
              try:
                  if DEBUG:
                      subprocess.run(command, check=True)
                  else:
                      subprocess.run(
                          command,
                          check=True,
                          stdout=subprocess.DEVNULL,
                          stderr=subprocess.DEVNULL,
                      )
              except Exception as exc:
                  if DEBUG:
                      log_debug(f"command failed ({' '.join(command)}): {exc}")


      def main() -> None:
          last_state = None
          while True:
              outputs = get_outputs()
              primary_enabled = is_primary_enabled(outputs)
              primary_state = "enabled" if primary_enabled else "not-enabled"
              dummy_should_enable = not primary_enabled

              if primary_state != last_state:
                  action = "enable" if dummy_should_enable else "disable"
                  log_debug(f"DP outputs are {primary_state}; {action} HDMI outputs")
                  last_state = primary_state

              set_dummy_enabled(outputs, dummy_should_enable)
              time.sleep(POLL_SECONDS)


      if __name__ == "__main__":
          main()
    '';
  };
in

{
  home.activation.removeLegacyPlasmaSymlinks = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    for file in \
      "${config.xdg.configHome}/kscreenlockerrc" \
      "${config.xdg.configHome}/powerdevilrc"
    do
      if [ -L "$file" ]; then
        $DRY_RUN_CMD rm $VERBOSE_ARG "$file"
      fi
    done
  '';

  home.packages = [
    displaySync
    pkgs."ubuntu-classic"
    pkgs.kdePackages.libkscreen
  ];

  # networking.firewall.enable = false;

  programs.plasma = {
    enable = true;
    configFile = {
      "kscreenlockerrc"."Daemon"."LockOnResume" = false;
      "powerdevilrc"."AC][Display" = {
        "TurnOffDisplayIdleTimeoutSec" = -1;
        "TurnOffDisplayWhenIdle" = false;
      };
      "powerdevilrc"."AC][SuspendAndShutdown"."AutoSuspendAction" = 0;
      "katerc"."KTextEditor Renderer"."Text Font" = kateHack10;
      "konsolerc"."Desktop Entry"."DefaultProfile" = "${konsoleProfileName}.profile";
    };
  };

  xdg.dataFile."konsole/${konsoleProfileName}.profile".text = lib.generators.toINI { } {
    General = {
      Name = konsoleProfileName;
      Parent = "FALLBACK/";
    };
    Appearance = {
      Font = konsoleUbuntuMono;
    };
  };

  xdg.configFile."MangoHud/MangoHud.conf".text = ''
    toggle_hud=F10
    fps
    frametime
    cpu_temp
    gpu_temp
    cpu_load
    gpu_load
  '';

  systemd.user.services.display-sync = {
    Unit = {
      Description = "Auto toggle HDMI outputs based on DisplayPort state";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${displaySync}/bin/display-sync";
      Restart = "always";
      RestartSec = 3;
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
