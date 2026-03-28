let
  genericPackages =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        git
        fzf
        ripgrep
        unzip
        gnumake
        gcc
        home-manager
        nixd
        nil
        zsh
      ];

    };
in
{
  flake.modules.nixos.cli-tools = {
    imports = [
      genericPackages
    ];
  };
}
