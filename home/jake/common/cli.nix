{ lib, pkgs, ... }:

{
  home.file.".screenrc".source = ./config/screenrc;
  
  programs.tmux = {
    enable = true;
    mouse = false;
    clock24 = true;
    historyLimit = 10000;

    # Stop tmux+escape craziness (no idea what that means)
    escapeTime = 0;

    extraConfig = ''
      # ---- Status bar base ----
      set -g status on
      set -g status-interval 5
      set -g status-position bottom
      #
      set -g status-left-length 60
      set -g status-right-length 120
      set -g status-justify left
      #
      set -g status-left "#[bold fg=colour39]#H #[fg=colour244]| #(whoami) "
      set -g status-right "#[fg=colour244]%Y-%m-%d #[fg=colour39]%H:%M"
      #

      # https://old.reddit.com/r/tmux/comments/mesrci/tmux_2_doesnt_seem_to_use_256_colors/
      set -g default-terminal "xterm-256color"
      set -ga terminal-overrides ",*256col*:Tc"
      set -ga terminal-overrides '*:Ss=\E[%p1%d q:Se=\E[ q'
      set-environment -g COLORTERM "truecolor"

      # easy-to-remember split pane commands
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"

      # ---- Pane context (recommended) ----
      set -g pane-border-format " #H "
      set -g pane-border-style fg=colour238
      set -g pane-active-border-style fg=colour39
      #
      # ---- Reload ----
      bind r source-file ~/.config/tmux/tmux.conf \; display "tmux reloaded"
    '';
  };
}
