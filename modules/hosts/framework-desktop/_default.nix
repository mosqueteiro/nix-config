{ self, inputs, ...}: {
  flake.nixosConfigurations.frameworkDesktop = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.frameworkDesktopConfiguration
    ];
  };
}
