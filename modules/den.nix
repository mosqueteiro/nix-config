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
      den.aspects.ai
    ];
    nixos =
      { pkgs, ... }:
      {
        imports = [
          ./_nixos/configuration.nix
          inputs.nixos-hardware.nixosModules.framework-desktop-amd-ai-max-300-series
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

        environment.variables.EDITOR = "vim";
        environment.systemPackages = [
          pkgs.vim
          pkgs.neovim
          pkgs.fd
          pkgs.git
          pkgs.gcc
          pkgs.gnumake
          pkgs.ghostscript
          pkgs.tectonic
          pkgs.imagemagick
          pkgs.mermaid-cli
          pkgs.sqlite
          pkgs.unzip
          pkgs.wget
          pkgs.npins
          pkgs.brave
          pkgs.btop-rocm
          pkgs.fastfetch
        ];

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

        # Linker shim for precompiled binaries not built for NixOS
        programs.nix-ld = {
          enable = true;
          libraries = [ pkgs.icu ];
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

  den.aspects.ai = {
    nixos =
      { pkgs, ... }:
      {
        # 1. Base ROCm & Graphics Support
        hardware.graphics = {
          enable = true;
          enable32Bit = true;
          extraPackages = with pkgs; [
            rocmPackages.clr.icd # Enables HIP/ROCm
          ];
        };
        hardware.amdgpu.opencl.enable = true;

        environment.variables = {
          # Required overrides for Strix Point/Halo (gfx1151)
          HSA_OVERRIDE_GFX_VERSION = "11.5.1";
          HCC_AMDGPU_TARGET = "gfx1151";
        };

        # 2. Native NixOS AI Services (Ollama & WebUI)
        services.ollama = {
          enable = true;
          package = pkgs.ollama-rocm;
          loadModels = [
            "gemma4:e4b"
            "gemma4:26b"
            "gemma4:31b"
          ];
        };
        services.open-webui.enable = true;

        # 3. Environment for Modular (MAX & Mojo) via Pixi
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

        # 4. System Packages
        environment.systemPackages = with pkgs; [
          # AI/ML Utilities
          rocmPackages.rocminfo
          rocmPackages.rocm-smi
          pixi
        ];
      };

    homeManager =
      { ... }:
      {
        home.sessionVariables = {
          # Required overrides for Strix Point/Halo (gfx1151)
          HSA_OVERRIDE_GFX_VERSION = "11.5.1";
          HCC_AMDGPU_TARGET = "gfx1151";
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

  den.aspects.mosqueteiro = {
    includes = [
      den.provides.define-user
      den.provides.primary-user
      (den.provides.user-shell "zsh")
      den.aspects.stable-nixpkgs
    ];
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
          pkgs.nil
          pkgs.nixd
          pkgs.wezterm
          pkgs.opencode
          pkgs.bitwarden-desktop
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
            };

            # initExtra = ''
            #   local_file=~/.local/share/zsh/something.zsh
            #   if [ -f $local_file ]; then
            #     source $local_file
            #   fi
            # '';
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
