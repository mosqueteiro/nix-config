{ ... }: {
  den.aspects.desktop-apps = {
    nixos = { pkgs, ...}: {
      # Install firefox.
      programs.firefox.enable = true;

      environment.systemPackages = [
        pkgs.brave
        pkgs.qalculate-qt
      ];
    };
  };
}
