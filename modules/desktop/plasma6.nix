{ den, ... }: {
  den.aspects.plasma6-desktop = {
    nixos = { ... }: {
      # X11 & Desktop
      services.xserver.enable = true;
      services.xserver.xkb = {
        layout = "us";
        variant = "";
      };

      services.displayManager.sddm.enable = true;
      services.displayManager.sddm.settings = {
        General = {
          Numlock = "on";
        };
      };

      services.desktopManager.plasma6.enable = true;
    };
  };
}
