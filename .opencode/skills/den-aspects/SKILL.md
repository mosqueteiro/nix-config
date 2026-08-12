---
name: den-aspects
description: Use when modifying modules/den.nix, writing or composing den aspects, adding packages to NixOS/home-manager, debugging den config/context errors, or inspecting the evaluated configuration.
compatibility: opencode
metadata:
  audience: nix-config
  workflow: den-aspect-editing
---

# Den Aspects

`modules/den.nix` and modular files under `modules/` — writing aspects, adding packages, or debugging den config. For the full framework reference see [`docs/DEN-REFERENCE.md`](../../../docs/DEN-REFERENCE.md).

## Core Workflow

1. **Find the right aspect** — packages/users go in an existing aspect (e.g. `frameworkDesktop` for system-wide, `mosqueteiro` for user). New concerns get a new aspect under `den.aspects.*`.
2. **Add nixos and/or homeManager blocks** — `nixos` for system-level config, `homeManager` for per-user. Use function form `{ pkgs, ... }: { ... }` when you need context.
3. **Use includes** to compose with other aspects: `includes = [ den.aspects.gaming den.provides.hostname ]`.
4. **Build and test** — `nixos-rebuild build --file . -A nixosConfigurations.frameworkDesktop`

## Key Patterns

| Pattern | Example |
|---------|---------|
| System packages | `environment.systemPackages = [ pkgs.vim ]` in `nixos` block |
| User packages | `home.packages = [ pkgs.vim ]` in `homeManager` block |
| Stable packages | `pkgs.stable.neovim` (needs `den.aspects.stable-nixpkgs` included) |
| Context dispatch | `({ host, ... }: { nixos.networking.hostName = host.hostName; })` |
| Built-in provides | `den.provides.hostname`, `den.provides.define-user`, `den.provides.primary-user`, `den.provides.user-shell "zsh"` |

## Debugging

```bash
# Type-check a config option
nix eval --file . nixosConfigurations.frameworkDesktop.config.networking.hostName

# Full config output
nix eval --file . nixosConfigurations.frameworkDesktop.config.system.build.toplevel

# Strict eval (catches errors)
nix eval --file . nixosConfigurations.frameworkDesktop.config.system.build.toplevel
```

To inspect what context variables are available, add a tracing include to the aspect:

```nix
den.aspects.foo.includes = [
  ({ host, ... }@ctx: builtins.trace ctx { nixos.foo = 1; })
];
```

## Safety Rails

- **Don't edit** `modules/hosts/framework-desktop/_hardware/hardware-configuration.nix` (auto-generated).
- **Don't edit** `npins/sources.json` or `npins/default.nix` manually.
- **State version** is `25.11` — don't bump it casually (see `docs/UPGRADE.md`).
- Aspects form a DAG via `includes` — no circular dependencies.
- Use `lib.mkDefault` / `lib.mkForce` for option priorities, not direct assignment.

## References

- [`docs/DEN-REFERENCE.md`](../../../docs/DEN-REFERENCE.md) — full reference (aspect structure, context system, includes/provides, code style)
- [`ARCHITECTURE.md`](../../../ARCHITECTURE.md) — repo structure, data flow, aspect DAG
- [Configure Aspects](https://den.oeiuwq.com/guides/configure-aspects/)
- [Context System](https://den.oeiuwq.com/explanation/context-system/)
- [Debug Guide](https://den.oeiuwq.com/guides/debug/)
