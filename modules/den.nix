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
      den.aspects.locale-denver
      den.aspects.allow-unfree
      den.aspects.desktop
      den.aspects.developer-tools
      den.aspects.gaming
      den.aspects.modular-ai
      den.aspects.ollama
      den.aspects.lemonade
      den.aspects.local-pkgs
    ];
    nixos =
      { pkgs, ... }:
      {
        imports = [
          ./hosts/framework-desktop/_hardware/hardware-configuration.nix
          inputs.nixos-hardware.nixosModules.framework-desktop-amd-ai-max-300-series
        ];

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

        # Bootloader.
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
        boot.initrd.systemd = {
          enable = true;
          tpm2.enable = true;
          fido2.enable = true;
        };

        boot.initrd.luks.devices."luks-73982fd7-f423-475c-972e-83a2f8de521a".crypttabExtraOpts = [
          "fido2-device=auto"
        ];

        security.tpm2.enable = true;

        zramSwap.enable = true;

        services.fwupd.enable = true;

        nix.settings.auto-optimise-store = true;

        # Enable networking
        networking.networkmanager.enable = true;

        # Configure network proxy if necessary
        # networking.proxy.default = "http://user:password@proxy:port/";
        # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

        environment.systemPackages = [
          pkgs.btop-rocm
        ];

        # Linker shim for precompiled binaries not built for NixOS
        programs.nix-ld = {
          enable = true;
          libraries = [ pkgs.icu ];
        };

        # devShell framework
        nix.settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          substituters = [ "https://nix-amd-ai.cachix.org" ];
          trusted-public-keys = [
            "nix-amd-ai.cachix.org-1:F4OU4vw/lV2oiG6SBHZ+nqjl4EFJuqI4X9A7pvaBmhQ="
          ];
        };
        programs.direnv = {
          enable = true;
          nix-direnv = {
            enable = true;
          };
        };

        # This value determines the NixOS release from which the default
        # settings for stateful data, like file locations and database versions
        # on your system were taken. It‘s perfectly fine and recommended to leave
        # this value at the release version of the first install of this system.
        # Before changing this value read the documentation for this option
        # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
        system.stateVersion = "25.11"; # Did you read the comment?
      };
  };

  den.aspects.allow-unfree = {
    nixos = { ... }: {
      nixpkgs.config.allowUnfree = true;
    };

    homeManager = { ... }: {
      nixpkgs.config.allowUnfree = true;
    };
  };

  den.aspects.locale-denver = {
    nixos = { ... }: {
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
    };
  };

  den.aspects.stable-nixpkgs = {
    nixos =
      { ... }:
      {
        nixpkgs.overlays = [
          (final: prev: {
            stable = import inputs.nixpkgs-stable {
              system = prev.stdenv.hostPlatform.system;
            };
          })
        ];
      };

    homeManager =
      { ... }:
      {
        nixpkgs.overlays = [
          (final: prev: {
            stable = import inputs.nixpkgs-stable {
              system = prev.stdenv.hostPlatform.system;
            };
          })
        ];
      };
  };

  den.aspects.ollama = {
    includes = [
      den.aspects.strix-halo-gpu
    ];
    nixos = { pkgs, ... }: {
      services.ollama = {
        enable = true;
        package = pkgs.ollama-rocm;
        loadModels = [
          "gemma4:e4b"
          "gemma4:26b"
          "gemma4:31b"
          "qwen3-coder-next"
        ];
      };

      services.open-webui.enable = true;
    };
  };

  den.aspects.modular-ai = {
    includes = [ den.aspects.strix-halo-gpu ];
    nixos =
      { pkgs, ... }:
      {
        # System Packages
        environment.systemPackages = with pkgs; [
          pixi
        ];

        # Environment for Modular (MAX & Mojo) via Pixi
        programs.nix-ld = {
          enable = true;
          # Add standard libraries that pre-compiled conda/pixi binaries need
          libraries = with pkgs; [
            stdenv.cc.cc.lib
            zlib
            rocmPackages.rocm-runtime # Provides libhsa-runtime64.so.1
            rocmPackages.clr # Provides libamdhip64.so
            rocmPackages.clr.icd # OpenCL/HIP ICDs
          ];
        };
      };
  };

  den.aspects.nix-amd-ai = {
    nixos =
      { ... }:
      {
        imports = [ inputs.nix-amd-ai.nixosModules.default ];

        hardware.amd-npu = {
          enable = true;
          enableNPU = true;
          enableVulkan = true;
          enableROCm = true;
          # enableFastFlowLM = false;
          # enableImageGen = false;
        };

        users.users.mosqueteiro.extraGroups = [
          "video"
          "render"
        ];
      };
  };

  den.aspects.lemonade = {
    includes = [ den.aspects.nix-amd-ai ];

    nixos =
      { ... }:
      {
        hardware.amd-npu = {
          enableLemonade = true;
          lemonade = {
            user = "mosqueteiro";
            desktopApp.enable = false;
          };
        };
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

  den.aspects.local-pkgs = {
    nixos =
      { ... }:
      {
        nixpkgs.overlays = [
          (final: prev: {
            allium-tools = final.callPackage ../pkgs/allium-tools { };
          })
        ];
      };
    homeManager =
      { ... }:
      {
        nixpkgs.overlays = [
          (final: prev: {
            allium-tools = final.callPackage ../pkgs/allium-tools { };
          })
        ];
      };
  };

  den.aspects.mosqueteiro = {
    includes = [
      den.provides.define-user
      den.provides.primary-user
      (den.provides.user-shell "zsh")
      den.aspects.allow-unfree
      den.aspects.stable-nixpkgs
    ];
    user = { ... }: {
      description = "Mosqueteiro";
    };

    homeManager =
      { pkgs, ... }:
      {
        home.sessionVariables.EDITOR = "nvim";
        home.packages = [
          pkgs.brave
          pkgs.vim
          pkgs.stable.neovim
          pkgs.ripgrep
          pkgs.nerd-fonts.daddy-time-mono
          pkgs.python314
          pkgs.nodejs_24
          pkgs.go
          pkgs.gh
          pkgs.nil
          pkgs.nixd
          pkgs.nixfmt
          pkgs.wezterm
          pkgs.opencode
          pkgs.bitwarden-desktop
          pkgs.tree
          pkgs.signal-desktop
          pkgs.discord
          pkgs.devenv
          pkgs.pandoc
          pkgs.poppler-utils
        ];

        programs = {
          git = {
            enable = true;
            settings.user = {
              name = "mosqueteiro";
              email = "nat3.th3.gr3at@gmail.com";
            };
          };

          zsh = {
            enable = true;
            enableCompletion = true;
            autosuggestion.enable = true;
            syntaxHighlighting.enable = true;
            initContent = lib.mkOrder 600 ''
              bindkey -v
              export KEYTIMEOUT=1
            '';

            shellAliases = {
              den-build = "nixos-rebuild build --file ~/nix-config/ -A nixosConfigurations.frameworkDesktop";
              den-test = "sudo nixos-rebuild test --file ~/nix-config/ -A nixosConfigurations.frameworkDesktop";
              den-suwitch = "sudo nixos-rebuild switch --file ~/nix-config/ -A nixosConfigurations.frameworkDesktop";
              cd = "z";
            };

            # initExtra = ''
            #   local_file=~/.local/share/zsh/something.zsh
            #   if [ -f $local_file ]; then
            #     source $local_file
            #   fi
            # '';
          };

          starship = {
            enable = true;
            settings = pkgs.lib.importTOML ./starship.toml;
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
            package = pkgs.btop-rocm;
            settings = {
              color_theme = "monokai";
              vim_keys = true;
            };
          };
        };
      };
  };
}
