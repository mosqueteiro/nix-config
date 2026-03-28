{ inputs, self, ... }:
let
  username = "mosqueteiro";
in
{
  flake.modules.nixos."${username}" =
    { ... }:
    {
      home-manager.users."${username}" = {
        imports = [
          inputs.self.modules.homeManager."${username}"
        ];
      };
    };

  flake.modules.homeManager."${username}" = {
    imports = [ ];

    home.username = "${username}";
    home.homeDirectory = "/home/${username}";
    home.stateVersion = "25.11";

    programs = {
      bash = {
        enable = true;
        enableCompletion = true;
      };

      zsh = {
        enable = true;
        enableCompletion = true;
      };

      zoxide = {
        enable = true;
        enableZshIntegration = true;
        enableBashIntegration = true;
      };
    };
  };
}
