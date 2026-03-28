let
  genericPackages = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      git
      fzf
      ripgrep
      unzip
      gnumake
      gcc
      nixd
      nil
    ];

    programs = {
      zoxide = {
        enable = true;
	enableBashIntegration = true;
      };
    };
  };
in
{
  flake.modules.nixos.cli-tools = {
    imports = [
      genericPackages
    ];
  };
}
