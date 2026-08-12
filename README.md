# Nix Configuration

This repo contains the source code for my Nix config including home-manager and NixOS for a Framework Desktop. It uses the [den] framework (no-flake template).

## Quick Start

```shell
# Build the system without switching (validates config)
nixos-rebuild build --file . -A nixosConfigurations.frameworkDesktop

# Apply configuration to running system
sudo nixos-rebuild switch --file . -A nixosConfigurations.frameworkDesktop

# Evaluate the configuration (type check)
nix eval --file . nixosConfigurations.frameworkDesktop.config.system.build.toplevel

# Update all dependencies
npins update
```

## Key Concepts

- **[Architecture](ARCHITECTURE.md)** — directory structure, data flow, aspect inclusion DAG, hardware overview.
- **[Den Framework Reference](docs/DEN-REFERENCE.md)** — no-flake pattern, aspect structure, context-driven dispatch, includes/provides, debugging.
- **[Upgrade Guide](docs/UPGRADE.md)** — npins update workflow, state version bumps, rollback strategies.
- **den** uses a **context-driven dispatch** system. Functions declare which context they need (host, user, or both) and only run when that context exists:

  ```nix
  # Runs everywhere
  { nixos.foo = 1; }
  # Runs only when {host} exists
  ({ host, ... }: { nixos.networking.hostName = host.hostName; })
  # Runs only when {host, user} exist
  ({ host, user, ... }: { nixos.users.users.${user.userName}.extraGroups = [ "wheel" ]; })
  ```

## Selective Stable Packages

This repo keeps `nixpkgs-unstable` as the main package source, and exposes `nixos-25.11` as `pkgs.stable` through `den.aspects.stable-nixpkgs` in `modules/den.nix`.

```nix
home.packages = [
  pkgs.stable.neovim
];
```

### Home Manager version warning

The current setup uses `nixpkgs-unstable` (26.11) while Home Manager may track a different release. To silence the non-blocking version mismatch warning:

```nix
home.enableNixpkgsReleaseCheck = false;
```

## Recreating from scratch

```shell
npins init                                  # adds nixpkgs channel
npins add github vic import-tree   -b main  # auto-importing ./modules
npins add github vic den           -b main  # den framework
npins add github vic with-inputs   -b main  # flake-like inputs without flakes
npins add github nix-community home-manager --branch master  # user-level config
npins add channel --name nixpkgs-stable nixos-25.11  # stable package source
npins add github NixOS nixos-hardware       # hardware modules
npins add github noamsto nix-amd-ai         # AMD NPU support
```

## Future changes

See [PLANS.md](PLANS.md) for the development roadmap and checklist.

## Resources

[den]: https://den.oeiuwq.com/ "Context-aware Dendritic Nix"
[From Zero to Den]: https://den.oeiuwq.com/guides/from-zero-to-den/
[Context System]: https://den.oeiuwq.com/explanation/context-system/
[nixos-hardware-framework-desktop]: https://github.com/NixOS/nixos-hardware/tree/master/framework/desktop/amd-ai-max-300-series
