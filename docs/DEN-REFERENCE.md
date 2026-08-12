# Den Framework Reference

A condensed cheatsheet for the den framework patterns used in this repository.

---

## Entry Point: The No-Flake Pattern

```
default.nix
  |-- imports npins           -> sources.json as Nix expressions
  |-- imports with-inputs     -> flake-like input wiring
  |-- calls evalModules with import-tree ./modules
  |
  v
modules/                    -> recursively imported modules
  |-- den.nix               -> imports den.flakeModule, declares host + user
  |-- desktop/*.nix         -> shared aspect definitions
  |-- hosts/*/              -> host-specific documentation and modules
  |
  v
.config.flake                -> consumed by nixos-rebuild --file . -A ...
```

### Key infrastructure pins (npins)

| Pin | Purpose |
|-----|---------|
| `with-inputs` | Wires npins sources into `inputs` attrset (like flake inputs) |
| `import-tree` | Recursively imports all `.nix` files under `modules/` |
| `den` | The den framework itself |
| `flake-aspects` | den's aspect system library |

---

## Host & User Declaration

```nix
den.hosts.x86_64-linux.frameworkDesktop.users = {
  mosqueteiro = { };
};
```

This creates:
- A NixOS config at `nixosConfigurations.frameworkDesktop`
- A home-manager config at `homeConfigurations.mosqueteiro` (per `den.schema.user.classes`)

---

## Aspect Structure

```nix
den.aspects.myAspect = {
  # optional: compose other aspects
  includes = [ den.aspects.something den.provides.something ];

  # optional: NixOS system-level config
  nixos = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.hello ];
  };

  # optional: home-manager user-level config
  homeManager = { pkgs, ... }: {
    home.packages = [ pkgs.hello ];
  };
};
```

Aspects can provide **nixos**, **homeManager**, or both. Den evaluates each only when the corresponding class exists for the host/user.

---

## Context-Driven Dispatch

Functions can destructure context variables. Den only evaluates when that context exists:

```nix
# Always evaluates (no function wrapper)
{ nixos.foo = 1; }

# Evaluates only when {host} exists
({ host, ... }: {
  nixos.networking.hostName = host.hostName;
})

# Evaluates only when {host, user} exist
({ host, user, ... }: {
  nixos.users.users.${user.userName}.extraGroups = [ "wheel" ];
})
```

### Available context variables

| Variable | Description |
|----------|-------------|
| `host` | The host declaration (e.g., `host.hostName`) |
| `user` | The user declaration (e.g., `user.userName`) |
| `config` | The full config (avoid unless necessary) |
| `pkgs` | nixpkgs (imported automatically) |
| `lib` | nixpkgs library functions |
| `inputs` | All npins inputs |

Use `builtins.trace` to inspect available context:

```nix
den.aspects.foo.includes = [
  ({ host, ... }@ctx: builtins.trace ctx { nixos.foo = 1; })
];
```

---

## Includes & Provides

### Includes (aspect composition)

Aspects declare dependencies via `includes`, forming a DAG:

```nix
den.aspects.frameworkDesktop = {
  includes = [
    den.provides.hostname        # built-in: sets hostname
    den.aspects.gaming           # another aspect
    den.aspects.ai
    den.aspects.lemonade
    den.aspects.local-pkgs
  ];
};
```

### Provides (named sub-aspects)

Create named sub-aspects:

```nix
den.aspects.tools.provides.editors
```

Built-in provides used in this repo:

| Provide | Effect |
|---------|--------|
| `den.provides.hostname` | Sets hostname from host config |
| `den.provides.define-user` | Creates the user account |
| `den.provides.primary-user` | Marks as the primary user |
| `den.provides.user-shell "zsh"` | Sets user shell to zsh |

---

## The Stable-nixpkgs Pattern

Overlays `pkgs.stable` using the pinned `nixpkgs-stable` channel:

```nix
den.aspects.stable-nixpkgs = {
  nixos = { ... }: {
    nixpkgs.overlays = [
      (final: prev: {
        stable = import inputs.nixpkgs-stable {
          system = prev.stdenv.hostPlatform.system;
        };
      })
    ];
  };
  homeManager = { ... }: {
    nixpkgs.overlays = [
      (final: prev: {
        stable = import inputs.nixpkgs-stable {
          system = prev.stdenv.hostPlatform.system;
        };
      })
    ];
  };
};
```

Usage: `pkgs.stable.neovim`, `pkgs.stable.ripgrep`, etc.

---

## Adding Packages

**System-wide (NixOS):**

```nix
den.aspects.frameworkDesktop.nixos = { pkgs, ... }: {
  environment.systemPackages = [ pkgs.vim ];
};
```

**Per-user (home-manager):**

```nix
den.aspects.mosqueteiro.homeManager = { pkgs, ... }: {
  home.packages = [ pkgs.vim ];
};
```

---

## den.schema Reference

```nix
# Require schema declaration for user-level aspects
den.schema.user.classes = lib.mkDefault [ "homeManager" ];

# Set default state version for all user configs
den.default.homeManager.home.stateVersion = "25.11";
```

---

## Debugging

```bash
# Type-check a specific option
nix eval --file . nixosConfigurations.frameworkDesktop.config.networking.hostName

# See full config (pipe to less)
nix eval --file . nixosConfigurations.frameworkDesktop.config.system.build.toplevel

# Strict evaluation (catches errors)
nix eval --file . nixosConfigurations.frameworkDesktop.config.system.build.toplevel

# Trace context variables in an aspect
# Add to den.nix:
den.aspects.foo.includes = [
  ({ host, ... }@ctx: builtins.trace ctx { nixos.foo = 1; })
];
```

---

## Code Style

| Rule | Convention |
|------|------------|
| Indentation | 2 spaces, no tabs |
| Attribute sets | `{ key = value; }` (space after colon) |
| Lists | Space-separated `[ item1 item2 ]` |
| Functions | `{ arg }: expression` over `args: expression` |
| Files | kebab-case |
| Options | camelCase |
| Overrides | `lib.mkDefault`, `lib.mkForce`, `assert`, `throw` |

---

## External References

- [From Zero to Den](https://den.oeiuwq.com/guides/from-zero-to-den/)
- [Configure Aspects](https://den.oeiuwq.com/guides/configure-aspects/)
- [Declare Hosts & Users](https://den.oeiuwq.com/guides/declare-hosts/)
- [den.schema Reference](https://den.oeiuwq.com/reference/schema/)
- [den.aspects Reference](https://den.oeiuwq.com/reference/aspects/)
- [Context System](https://den.oeiuwq.com/explanation/context-system/)
- [Core Principles](https://den.oeiuwq.com/explanation/core-principles/)
- [Debug Guide](https://den.oeiuwq.com/guides/debug/)
- [No-Flake Template](https://den.oeiuwq.com/tutorials/noflake/)
