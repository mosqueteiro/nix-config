{ den, ... }: {
  den.aspects.desktop = {
    includes = [
      den.aspects.common-cli
      den.aspects.desktop-apps
    ];
    nixos = { ... }: {
      # Sound
      ## Enable sound with pipewire.
      services.pulseaudio.enable = false;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        # If you want to use JACK applications, uncomment this
        #jack.enable = true;

        # use the example session manager (no others are packaged yet so this is enabled by default,
        # no need to redefine it in your config for now)
        #media-session.enable = true;
      };

      # Bluetooth
      hardware.bluetooth.enable = true;

    };
  };

  den.aspects.desktop-apps = {
    includes = [ den.aspects.allow-unfree ];
    nixos = { pkgs, ... }: {
      programs.firefox.enable = true;

      environment.systemPackages = [
        pkgs.brave # unfree
        pkgs.qalculate-qt
      ];

      # Set Brave as default browser
      xdg.mime.defaultApplications = {
        "text/html" = "brave-browser.desktop";
        "x-scheme-handler/http" = "brave-browser.desktop";
        "x-scheme-handler/https" = "brave-browser.desktop";
      };

    };
  };

  den.aspects.developer-tools = {
    includes = [
      den.aspects.common-cli
      den.aspects.local-pkgs
      den.aspects.allow-unfree
    ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [
        pkgs.neovim
        pkgs.git
        pkgs.gcc
        pkgs.gnumake
        pkgs.ghostscript
        pkgs.tectonic
        pkgs.imagemagick
        pkgs.mermaid-cli
        pkgs.sqlite
        pkgs.tlrc
        pkgs.allium-tools
        pkgs.mojo
      ];
    };
  };

  den.aspects.virtualisation = {
    nixos = { ... }: {
      virtualisation.podman = {
        enable = true;
        defaultNetwork.settings.dns_enabled = true;
      };
    };
  };

  den.aspects.common-cli = {
    nixos = { pkgs, ... }: {
      environment.variables.EDITOR = "vim";
      environment.systemPackages = [
        pkgs.fd
        pkgs.fastfetch
        pkgs.jq
        pkgs.vim
        pkgs.unzip
        pkgs.wget
        pkgs.nixfmt
        pkgs.npins
      ];
    };
  };
}
