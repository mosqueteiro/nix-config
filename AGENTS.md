# Agent Guidelines for Nix Configuration

This is a NixOS/home-manager configuration repository using the [den](https://den.oeiuwq.com/) framework (no-flake template). It manages a Framework Desktop system with NixOS and Plasma6.

## Build/Lint/Test Commands

```bash
# Build the system without switching (validates config)
nixos-rebuild build --file . -A nixosConfigurations.frameworkDesktop
# Or use the shell alias (if zsh is active)
den-build
```

After changes are validated, present this command to the user to apply (requires sudo — agent cannot run sudo):

```bash
# Apply configuration to running system
sudo nixos-rebuild switch --file . -A nixosConfigurations.frameworkDesktop
# Or use the shell alias (if zsh is active)
sudo den-suwitch
```

Other useful commands:

```bash
# Evaluate the configuration (type check)
nix eval --file . nixosConfigurations.frameworkDesktop.config.system.build.toplevel

# Update dependencies (npins)
npins update
```

### Linting/Formatting

```bash
nil check /path/to/file.nix  # Check a file with nil (Nix language server)
nix fmt                      # Format Nix code
nix eval --file . nixosConfigurations.frameworkDesktop.config.system.build.toplevel  # Check for evaluation errors
```

## Key Files

| File | Purpose |
|------|---------|
| `default.nix` | Entry point — wires npins, with-inputs, import-tree |
| `modules/den.nix` | Central configuration — hosts, users, and aspect definitions |
| `modules/desktop/desktop.nix` | Desktop applications aspect |
| `modules/hosts/framework-desktop/_hardware/hardware-configuration.nix` | Hardware (auto-generated, do not edit) |
| `modules/hosts/framework-desktop/README.md` | Framework Desktop hardware and TPM/FIDO2 documentation |
| `npins/sources.json` | Pinned dependencies (do not edit manually) |
| `ARCHITECTURE.md` | Repo structure, data flow, aspect inclusion DAG |
| `docs/DEN-REFERENCE.md` | Den framework patterns cheatsheet |
| `docs/UPGRADE.md` | Upgrade, rollback, and state version guide |

## Code Style

- **Indentation**: 2 spaces, no tabs
- **Attribute Sets**: `{ key = value; }` (space after colon)
- **Lists**: Space-separated `[ item1 item2 ]`
- **Functions**: `{ arg }: expression` over `args: expression`
- **Files**: kebab-case (`hardware-configuration.nix`)
- **Options**: camelCase (`boot.loader.systemd-boot.enable`)
- **Error Handling**: `lib.mkDefault`, `lib.mkForce`, `assert`, `throw`

## Den Aspects (Quick Reference)

Aspects consolidate config across NixOS and home-manager:

```nix
den.aspects.myFeature = {
  nixos = { pkgs, ... }: { /* system config */ };
  homeManager = { pkgs, ... }: { /* user config */ };
};
```

See [`docs/DEN-REFERENCE.md`](docs/DEN-REFERENCE.md) for the full reference. Load the `den-aspects` skill when modifying aspects in `modules/den.nix` or other aspect modules under `modules/`.

## npins

- Do NOT edit `npins/default.nix` or `npins/sources.json` manually
- Use `npins add` and `npins update` to manage dependencies
- See `docs/UPGRADE.md` for upgrade workflows; load the `npins-update` skill for detailed guidance

## Reference Docs

- [ARCHITECTURE.md](ARCHITECTURE.md) — repo structure & data flow
- [docs/DEN-REFERENCE.md](docs/DEN-REFERENCE.md) — den framework patterns
- [docs/UPGRADE.md](docs/UPGRADE.md) — upgrades & rollback
- [modules/hosts/framework-desktop/README.md](modules/hosts/framework-desktop/README.md) — hardware specs & TPM enrollment

## Notes

- State version: `25.11`
- System: btrfs with LUKS encryption
- Desktop: Plasma6 with SDDM
- Framework: uses den's `frameworkDesktop` aspect and `mosqueteiro` user aspect
