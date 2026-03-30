# Agent Guidelines for Nix Configuration

This is a NixOS/home-manager configuration repository using the [den](https://den.oeiuwq.com/) framework (no-flake template). It manages a Framework Desktop system with NixOS and Plasma6.

See [From Zero to Den](https://den.oeiuwq.com/guides/from-zero-to-den/) and [No-Flake Template](https://den.oeiuwq.com/tutorials/noflake/) for the template this was built from.

## Build/Lint/Test Commands

```bash
# Evaluate the configuration (type check)
nix eval . --attr nixosConfigurations.frameworkDesktop.config.system.build.toplevel

# Build the system without switching
nixos-rebuild build --file . -A nixosConfigurations.frameworkDesktop

# Test configuration without adding to boot menu
sudo nixos-rebuild test --file . -A nixosConfigurations.frameworkDesktop

# Apply configuration to running system
sudo nixos-rebuild switch --file . -A nixosConfigurations.frameworkDesktop

# Update dependencies (npins)
npins upgrade
```

### Linting/Formatting

```bash
nil check /path/to/file.nix  # Check a file with nil (Nix language server)
nix fmt                      # Format Nix code
nix eval . --strict 2>&1 | grep -i error  # Check for errors
```

## den Framework Concepts

Read [Core Principles](https://den.oeiuwq.com/explanation/core-principles/) for background.

### Aspects

Aspects consolidate a single concern across Nix classes (nixos, homeManager, darwin):

```nix
den.aspects.myFeature = {
  nixos = { pkgs, ... }: { /* NixOS config */ };
  homeManager = { pkgs, ... }: { /* home-manager config */ };
};
```

### Context-Driven Dispatch

Functions declare which context they need - Den runs them only when that context exists:

```nix
# Runs everywhere
{ nixos.foo = 1; }
# Runs only when {host} exists
({ host, ... }: { nixos.networking.hostName = host.hostName; })
# Runs only when {host, user} exist
({ host, user, ... }: { nixos.users.users.${user.userName}.extraGroups = [ "wheel" ]; })
```

See [Context System](https://den.oeiuwq.com/explanation/context-system/) for details.

### Includes

Aspects form a DAG through `includes`:

```nix
den.aspects.workstation = {
  includes = [ den.aspects.dev-tools den.provides.primary-user ];
  nixos.services.xserver.enable = true;
};
```

### Provides

Creates named sub-aspects: `den.aspects.tools.provides.editors`

## This Repository's Structure

### Key Files

| File | Purpose |
|------|---------|
| `default.nix` | Entry point - connects import-tree and npins |
| `modules/den.nix` | Main den configuration (hosts, users, aspects) |
| `modules/_nixos/configuration.nix` | NixOS system config |
| `modules/_nixos/hardware-configuration.nix` | Hardware (auto-generated, do not edit) |
| `npins/sources.json` | Pinned dependencies |

### Host/User Declaration

```nix
den.hosts.x86_64-linux.frameworkDesktop.users = {
  mosqueteiro = { };
};
```

### Adding Packages

**NixOS (system-wide):**
```nix
den.aspects.frameworkDesktop.nixos = { pkgs, ... }: {
  environment.systemPackages = [ pkgs.vim ];
};
```

**home-manager (per user):**
```nix
den.aspects.mosqueteiro.homeManager = { pkgs, ... }: {
  home.packages = [ pkgs.vim ];
};
```

### Adding Users

See [Declare Hosts & Users](https://den.oeiuwq.com/guides/declare-hosts/) guide.

## Code Style

- **Indentation**: 2 spaces, no tabs
- **Attribute Sets**: `{ key = value; }` (space after colon)
- **Lists**: Space-separated `[ item1 item2 ]`
- **Functions**: `{ arg }: expression` over `args: expression`
- **Files**: kebab-case (`hardware-configuration.nix`)
- **Options**: camelCase (`boot.loader.systemd-boot.enable`)
- **Error Handling**: `lib.mkDefault`, `lib.mkForce`, `assert`, `throw`

## Working with npins

- Do NOT edit `npins/default.nix` or `npins/sources.json` manually
- Use `npins add` and `npins upgrade` to manage dependencies

## Debugging Strategies

REPL is interactive - use for user guidance. Agents should use:

1. **Type checking**: `nix eval . --attr ...` catches type errors
2. **Trace context**: Add `builtins.trace` to see available context:
   ```nix
   den.aspects.foo.includes = [ ({ host, ... }@ctx: builtins.trace ctx { nixos.foo = 1; }) ];
   ```
3. **Inspect config**: `nix eval . --attr nixosConfigurations.frameworkDesktop.config.networking.hostName`
4. **Reference**: See [Debug Guide](https://den.oeiuwq.com/guides/debug/)

## Relevant Documentation Links

- [From Zero to Den](https://den.oeiuwq.com/guides/from-zero-to-den/)
- [Configure Aspects](https://den.oeiuwq.com/guides/configure-aspects/)
- [Declare Hosts & Users](https://den.oeiuwq.com/guides/declare-hosts/)
- [den.schema Reference](https://den.oeiuwq.com/reference/schema/)
- [den.aspects Reference](https://den.oeiuwq.com/reference/aspects/)
- [Context System](https://den.oeiuwq.com/explanation/context-system/)
- [Core Principles](https://den.oeiuwq.com/explanation/core-principles/)

## Notes

- State version: "25.11"
- System: btrfs with LUKS encryption
- Desktop: Plasma6 with SDDM
- Framework: uses den's `frameworkDesktop` aspect and `mosqueteiro` user aspect
