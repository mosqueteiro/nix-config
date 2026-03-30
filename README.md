# Nix Configuration

This repo contains the source code for my Nix config including home-manager and NixOS for my framework desktop.

It is modeled using the [den] framework and following the [From Zero to Den] guide.

## Current setup

### default.nix
The [./default.nix] file is the entrypoint which connects everything together. It should almost never need to be edited.

### npins/
The npins tool is used for dependency pinning which controls the [./npins/] directory. To bootstrap this configuration, use `nix-shell -p npins` to be able to use npins before it's been added through this configuration. The following tools are added with `npins` to get den and the tools that integrate everything together.

```shell
npins init                                  # adds nixpkgs channel
npins add github vic import-tree   -b main  # for auto-importing ./modules
npins add github vic den           -b main  # Den itself, of course
npins add github vic with-inputs   -b main  # flake-like inputs without Nix flakes.
npins add github nix-community home-manager --branch master # OPTIONAL home integration
```

### modules/

The modules directory holds all the configuration code for hosts and users.

### den.nix

The [./modules/den.nix] file configures most of the things.

## Quick Start

```shell
# Evaluate the configuration (type check)
nix eval . --attr nixosConfigurations.frameworkDesktop.config.system.build.toplevel

# Build the system without switching
nixos-rebuild build --file . -A nixosConfigurations.frameworkDesktop

# Apply configuration to running system
sudo nixos-rebuild switch --file . -A nixosConfigurations.frameworkDesktop
```

## How It Works

den uses a **context-driven dispatch** system. Functions declare which context they need (host, user, or both) and only run when that context exists:

```nix
# Runs everywhere
{ nixos.foo = 1; }

# Runs only when {host} exists
({ host, ... }: { nixos.networking.hostName = host.hostName; })

# Runs only when {host, user} exist
({ host, user, ... }: { nixos.users.users.${user.userName}.extraGroups = [ "wheel" ]; })
```

**Aspects** consolidate a single concern across Nix classes (NixOS, home-manager, darwin). This system is explained in the [Context System] documentation.

## Future changes

- [ ] add Framework specific firmware
- [ ] add GPU support
- [ ] develop gaming aspect
- [ ] develop AI hosting aspect
- slowly move things out of the **_nixos** files into respective aspects of the code

## Resources

[den]: https://den.oeiuwq.com/ "Context-aware Dendritic Nix"
[From Zero to Den]: https://den.oeiuwq.com/guides/from-zero-to-den/
[Context System]: https://den.oeiuwq.com/explanation/context-system/
