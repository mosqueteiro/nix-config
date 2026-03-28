{ inputs, ... }:
{
  # Manage user environments using Nix
  flake.inputs = {
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  imports = [ inputs.home-manager.flakeModules.home-manager ];
}
