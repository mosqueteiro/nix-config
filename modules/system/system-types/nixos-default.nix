{ inputs, ... }: {

  flake.modules.nixos.system-default = { pkgs, ... }: {

    nixpkgs.config.allowUnfree = true;

    imports = with inputs.self.modules.nixos; [
      cli-tools
    ];

  };
}
