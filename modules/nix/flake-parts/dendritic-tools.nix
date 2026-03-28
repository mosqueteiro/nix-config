{ inputs, ... }: {

  # Setup of tools for dendritic pattern

  flake.inputs = {

    # Simplify Nix Flakes with module system
    flake-parts.url = "github:hercules-ci/flake-parts";

    # Generate flake.nix from module options
    flake-file.url = "github:vic/flake-file";

    # Import all nix files into a directory tree
    import-tree.url = "github:vic/import-tree";
  };

  imports = [
    inputs.flake-parts.flakeModules.modules
    inputs.flake-file.flakeModules.default
  ];

  # Import all modules recursively with import-tree
  flake-file.outputs = ''
    inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules)
  '';

  # Set flake.systems
  systems = [
    "aarch64-darwin"
    "aarch64-linux"
    "x86_64-darwin"
    "x86_64-linux"
  ];
}
