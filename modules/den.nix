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
    includes = [ den.provides.hostname ];
    nixos =
      { pkgs, ... }:
      {
        imports = [ ./_nixos/configuration.nix ];
        environment.systemPackages = [
          pkgs.vim
          pkgs.neovim
          pkgs.git
          pkgs.gcc
          pkgs.gnumake
          pkgs.unzip
          pkgs.npins
          pkgs.brave
        ];
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
        home.packages = [
          pkgs.vim
          pkgs.neovim
          pkgs.ripgrep
          # other things for neovim: nerdfonts, npm, go, python
          pkgs.wezterm
          pkgs.brave
        ];

        programs.git = {
          enable = true;
          userName = "mosqueteiro";
          userEmail = "nat3.th3.gr3at@gmail.com";
        };
      };
  };
}
