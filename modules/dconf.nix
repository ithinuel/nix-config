{ lib, ... }: [{
  settings = with lib.gvariant; {
    "com/gexperts/Tilix" = {
      accelerators-enabled = true;
      focus-follow-mouse = true;
      prompt-on-close = true;
      theme-variant = "dark";
    };

    # this magic uuid is the default profile id used by Tilix
    # see https://github.com/gnunn1/tilix/blob/9dee5ad10138f609769906ca1f554c3a9ff2b1ba/source/gx/tilix/preferences.d#L320
    "com/gexperts/Tilix/profiles/2b7c4080-0ddd-46c5-8f23-563fd3ba789d" = {
      scrollback-unlimited = true;
      visible-name = "Default";
    };

    "org/gnome/TextEditor" = {
      highlight-current-line = true;
      show-grid = false;
      show-line-numbers = true;
      show-map = false;
      show-right-margin = false;
      wrap-text = true;
    };

    "org/gnome/baobab/ui" = {
      active-chart = "rings";
    };

    "org/gnome/calculator" = {
      accuracy = mkInt32 9;
      angle-units = "degrees";
      base = mkInt32 10;
      button-mode = "programming";
      number-format = "automatic";
      show-thousands = false;
      show-zeroes = false;
      source-currency = "";
      source-units = "degree";
      target-currency = "";
      target-units = "radian";
      window-maximized = false;
    };

    "org/gnome/desktop/interface" = {
      accent-color = "purple";
      color-scheme = "prefer-dark";
    };

    "org/gnome/desktop/wm/keybindings" = {
      switch-applications = mkEmptyArray type.string;
      switch-applications-backward = mkEmptyArray type.string;
      switch-windows = mkArray [ "<Alt>Tab" ];
      switch-windows-backward = mkArray [ "<Shift><Alt>Tab" ];
    };

    "org/gnome/desktop/wm/preferences" = {
      focus-mode = "sloppy";
    };

    "org/gnome/evince/default" = {
      continuous = true;
      dual-page = false;
      dual-page-odd-left = false;
      enable-spellchecking = true;
      fullscreen = false;
      inverted-colors = false;
      show-sidebar = true;
      sidebar-page = "thumbnails";
      sizing-mode = "automatic";
    };

    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "list-view";
    };
  };
}]
