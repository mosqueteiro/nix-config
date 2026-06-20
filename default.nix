let
  sources = import ./npins;
  with-inputs = import sources.with-inputs sources {
    nix-amd-ai.inputs.flake-parts.follows = "nix-amd-ai-flake-parts";
    nix-amd-ai.inputs.nix-darwin.follows = "nix-amd-ai-nix-darwin";
    nix-amd-ai-flake-parts.inputs.nixpkgs-lib.follows = "nix-amd-ai-nixpkgs-lib";
  };

  outputs =
    inputs:
    (inputs.nixpkgs.lib.evalModules {
      modules = [ (inputs.import-tree ./modules) ];
      specialArgs.inputs = inputs;
    }).config.flake;
in
with-inputs outputs
