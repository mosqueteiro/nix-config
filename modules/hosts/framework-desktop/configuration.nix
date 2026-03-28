{ self, inputs, ... }:
{
  flake.modules.nixos.frameworkDesktop =
    { config, pkgs, ... }:
    {
      # imports =
      #   [ # Include the results of the hardware scan.
      #     self.nixosModules.frameworkDesktopHardware
      #   ];

      imports = with inputs.self.modules.nixos; [
        system-default
      ];
      # imports = [
      #   inputs.self.modules.nixos.system-default
      #   inputs.self.modules.nixos.home-manager
      # ];

      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      # Bootloader.
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      boot.initrd.systemd = {
        enable = true;
        tpm2.enable = true;
      };

      security.tpm2.enable = true;

      zramSwap.enable = true;

      services.fwupd.enable = true;

      networking.hostName = "nixos"; # Define your hostname.
      # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

      # Configure network proxy if necessary
      # networking.proxy.default = "http://user:password@proxy:port/";
      # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

      # Enable networking
      networking.networkmanager.enable = true;

      # Set your time zone.
      time.timeZone = "America/Denver";

      # Select internationalisation properties.
      i18n.defaultLocale = "en_US.UTF-8";

      i18n.extraLocaleSettings = {
        LC_ADDRESS = "en_US.UTF-8";
        LC_IDENTIFICATION = "en_US.UTF-8";
        LC_MEASUREMENT = "en_US.UTF-8";
        LC_MONETARY = "en_US.UTF-8";
        LC_NAME = "en_US.UTF-8";
        LC_NUMERIC = "en_US.UTF-8";
        LC_PAPER = "en_US.UTF-8";
        LC_TELEPHONE = "en_US.UTF-8";
        LC_TIME = "en_US.UTF-8";
      };

      # Enable the X11 windowing system.
      # You can disable this if you're only using the Wayland session.
      services.xserver.enable = true;

      # Enabling displaylink
      services.xserver.videoDrivers = [
        "displaylink"
        "modesetting"
      ];
      # To connect a second external monitor
      # services.xserver.displayManager.sessionCommands = ''
      #   ${lib.getBin pkgs.xorg.xrandr}/bin/xrandr --setprovideroutputsource 2 0
      # '';

      # Enable the KDE Plasma Desktop Environment.
      services.displayManager.sddm.enable = true;
      services.desktopManager.plasma6.enable = true;

      # Configure keymap in X11
      services.xserver.xkb = {
        layout = "us";
        variant = "";
      };

      # Enable CUPS to print documents.
      services.printing.enable = true;

      # Enable sound with pipewire.
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

      # Enable touchpad support (enabled default in most desktopManager).
      # services.xserver.libinput.enable = true;

      # Define a user account. Don't forget to set a password with ‘passwd’.
      users.users.mosqueteiro = {
        isNormalUser = true;
        description = "Mosqueteiro";
        extraGroups = [
          "networkmanager"
          "wheel"
        ];
        packages = with pkgs; [
          kdePackages.kate
          #  thunderbird
        ];
      };
      # home-manager.users.mosqueteiro = {
      #   ###
      # };

      # Install firefox.
      programs.firefox.enable = true;

      # Allow unfree packages
      nixpkgs.config.allowUnfree = true;

      # List packages installed in system profile. To search, run:
      # $ nix search wget
      environment.systemPackages = with pkgs; [
        #  wget
        neovim
        brave
        btop
        fastfetch

        displaylink # needs to prefetch a file first
      ];

      # Some programs need SUID wrappers, can be configured further or are
      # started in user sessions.
      # programs.mtr.enable = true;
      # programs.gnupg.agent = {
      #   enable = true;
      #   enableSSHSupport = true;
      # };

      # List services that you want to enable:

      # Enable the OpenSSH daemon.
      # services.openssh.enable = true;

      # Open ports in the firewall.
      # networking.firewall.allowedTCPPorts = [ ... ];
      # networking.firewall.allowedUDPPorts = [ ... ];
      # Or disable the firewall altogether.
      # networking.firewall.enable = false;

      # This value determines the NixOS release from which the default
      # settings for stateful data, like file locations and database versions
      # on your system were taken. It‘s perfectly fine and recommended to leave
      # this value at the release version of the first install of this system.
      # Before changing this value read the documentation for this option
      # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
      system.stateVersion = "25.11"; # Did you read the comment?

    };
}
