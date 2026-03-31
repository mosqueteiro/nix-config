{
  inputs,
  den,
  lib,
  ...
}:
{
  imports = [ inputs.den.flakeModule ];

  den.schema.user.classes = lib.mkDefault [ "homeManager" ];

  den.default.homeManager.home.stateVersion = "25.11";

  den.hosts.x86_64-linux.frameworkDesktop.users = {
    mosqueteiro = { };
  };

  den.aspects.frameworkDesktop = {
    includes = [
      den.provides.hostname
      den.aspects.gaming
    ];
    nixos =
      { pkgs, ... }:
      {
        imports = [
          ./_nixos/configuration.nix
          inputs.nixos-hardware.nixosModules.framework-desktop-amd-ai-max-300-series
        ];
        services.fwupd.enable = true;
        environment.variables.EDITOR = "vim";
        environment.systemPackages = [
          pkgs.vim
          pkgs.neovim
          pkgs.git
          pkgs.gcc
          pkgs.gnumake
          pkgs.unzip
          pkgs.npins
          pkgs.brave
          pkgs.btop
          pkgs.fastfetch
        ];

        # Sound
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

        # Bluetooth
        hardware.bluetooth.enable = true;

      };
  };

  den.aspects.gaming = {
    nixos =
      { ... }:
      {
        programs.gamescope.enable = true;
        programs.steam.enable = true;
      };
  };

  den.aspects.mosqueteiro = {
    includes = [
      den.provides.define-user
      den.provides.primary-user
      (den.provides.user-shell "zsh")
    ];
    homeManager =
      { pkgs, ... }:
      {
        home.sessionVariables.EDITOR = "nvim";
        home.packages = [
          pkgs.brave
          pkgs.vim
          pkgs.neovim
          pkgs.ripgrep
          pkgs.nerd-fonts.daddy-time-mono
          pkgs.python314
          pkgs.go
          pkgs.nil
          pkgs.nixd
          pkgs.wezterm
          pkgs.opencode
        ];

        programs = {
          git = {
            enable = true;
            settings.user.email = "nat3.th3.gr3at@gmail.com";
            settings.user.name = "mosqueteiro";
          };

          zsh = {
            enable = true;
          };

          fzf = {
            enable = true;
            enableBashIntegration = true;
            enableZshIntegration = true;
          };

          zoxide = {
            enable = true;
            enableZshIntegration = true;
            enableBashIntegration = true;
          };

          btop = {
            enable = true;
            settings = {
              color_theme = "monokai";
              vim_keys = true;
            };
          };
        };
      };
  };
}
