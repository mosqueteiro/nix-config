# Architecture

This document describes the structure and design of this NixOS/home-manager configuration repository, which uses the [den](https://den.oeiuwq.com/) framework in the no-flake template.

## System Overview

| Property | Value |
|----------|-------|
| Machine | Framework Desktop (AMD Ryzen AI Max+ 395, 32-core) |
| GPU | AMD Radeon 8060S (RDNA 3.5 / Strix Point / gfx1151) |
| RAM | 128 GB |
| Storage | Single NVMe, LUKS encrypted, btrfs (subvolumes: `@`, `@home`) |
| Boot | UEFI, systemd-boot, TPM2 passwordless unlock |
| Desktop | KDE Plasma 6 on Wayland (via SDDM) |
| Sound | PipeWire (ALSA + PulseAudio compat) |
| State Version | 25.11 |

---

## Directory Structure

```
.
|-- default.nix                         # Entry point
|-- AGENTS.md                           # Agent/AI assistant guidelines
|-- ARCHITECTURE.md                     # This file
|-- PLANS.md                            # Development plans & checklist
|-- README.md                           # Project overview & quick start
|-- nix-system.allium                   # Allium architectural spec (documentation)
|-- LICENSE                             # Unlicense (public domain)
|-- modules/
|   |-- den.nix                         # Central config: hosts, users, aspects
|   |-- starship.toml                   # Starship prompt theme
|   |-- _nixos/
|       |-- configuration.nix           # NixOS system config (legacy bucket)
|       |-- hardware-configuration.nix  # Auto-generated hardware scan
|       |-- README.md                   # TPM/LUKS enrollment docs
|-- npins/
|   |-- default.nix                     # Fetcher library (auto-generated)
|   |-- sources.json                    # Pinned dependency manifest
|-- pkgs/
|   |-- allium-tools/
|       |-- default.nix                 # Custom package: allium CLI
```

---

## Data Flow

```
npins/sources.json
  |
  v
npins/default.nix          # Fetcher: converts sources.json to Nix expressions
  |
  v
default.nix                # Entry point
  |-- imports npins
  |-- imports with-inputs          # Flake-like input wiring (no flake.nix)
  |-- calls with-inputs with input-follow overrides
  |-- feeds inputs into evalModules
  |-- imports modules/ via import-tree
  |
  v
modules/                   # Auto-imported by import-tree
  |-- den.nix              # The only module file
       |
       |-- imports den.flakeModule
       |-- declares: host = frameworkDesktop, user = mosqueteiro
       |-- defines 6+ aspects (groups of config)
       |
       v
den                         # Evaluates aspects contextually:
  |-- nixos blocks  -> nixosConfigurations.frameworkDesktop
  |-- homeManager blocks -> homeConfigurations.mosqueteiro
  |
  v
.config.flake              # Final output, consumed by nixos-rebuild
```

### How the no-flake pattern works

1. **Pinning**: `npins/sources.json` pins all external dependencies (nixpkgs, den, home-manager, etc.) with exact revisions and hashes.
2. **Fetchers**: `npins/default.nix` converts `sources.json` into importable Nix expressions.
3. **Input wiring**: `default.nix` uses the `with-inputs` tool to collect all npins sources into an `inputs` attrset (simulating flake inputs), then calls `evalModules` with `import-tree` to recursively import `modules/`.
4. **Module evaluation**: `modules/den.nix` is the only module. It imports the den flake module, declares the host and user, and defines all aspects.
5. **Contextual dispatch**: den evaluates `nixos` attributes for the host context and `homeManager` attributes for the user context. Functions can conditionally apply config based on available context (e.g., `{ host, user, ... }`).
6. **Output**: The final configuration is exposed as `config.flake`, consumed by `nixos-rebuild --file . -A nixosConfigurations.frameworkDesktop`.

---

## The den Framework

[den](https://den.oeiuwq.com/) is a Nix framework that consolidates configuration across Nix classes (NixOS, home-manager, darwin) using **aspects**.

### Aspects

Aspects group related configuration into composable units:

```nix
den.aspects.myFeature = {
  nixos = { pkgs, ... }: {
    # NixOS system-level config
  };
  homeManager = { pkgs, ... }: {
    # home-manager user-level config
  };
};
```

### Context-Driven Dispatch

Functions declare which context variables they need, and den evaluates them only when that context exists:

- `{ nixos.foo = 1; }` — runs everywhere
- `({ host, ... }: { ... })` — runs only when a host exists
- `({ host, user, ... }: { ... })` — runs only when both host and user exist

### Includes

Aspects form a DAG through `includes`, enabling composition:

```nix
den.aspects.workstation = {
  includes = [ den.aspects.dev-tools den.provides.primary-user ];
  nixos = { ... };
};
```

---

## Aspects Defined

### `den.aspects.frameworkDesktop` (Host-level)

The main host aspect. Includes all other host aspects.

**NixOS**:
- **Imports** `modules/_nixos/configuration.nix` (legacy bucket) + `nixos-hardware.framework-desktop-amd-ai-max-300-series`
- **Display**: SDDM (Numlock on) → KDE Plasma 6
- **Boot**: systemd-boot, TPM2, initrd systemd
- **Memory**: zramSwap
- **Firmware**: fwupd
- **Sound**: PipeWire (ALSA + PulseAudio compat)
- **Bluetooth**: enabled
- **Direnv**: enabled with nix-direnv
- **nix-ld**: enabled (dynamic binary compatibility)
- **Nix**: flakes + nix-command, `nix-amd-ai.cachix.org` substituter
- **System packages**: vim, neovim, git, gcc, gnumake, fd, sqlite, npins, ghostscript, tectonic, imagemagick, mermaid-cli, unzip, wget, fastfetch, brave, btop-rocm, allium-tools

**Includes**:
- `den.provides.hostname` — built-in: sets hostname from host config
- `den.aspects.gaming`
- `den.aspects.ai`
- `den.aspects.lemonade`
- `den.aspects.local-pkgs`

---

### `den.aspects.gaming` (NixOS)

- `programs.gamescope.enable = true`
- `programs.steam.enable = true`

---

### `den.aspects.ai` (NixOS + homeManager)

**NixOS**:
- **GPU/ROCm**: graphics enabled, AMDGPU OpenCL, ROCm ICD
- **Environment overrides**: `HSA_OVERRIDE_GFX_VERSION="11.5.1"`, `HCC_AMDGPU_TARGET="gfx1151"` (Strix Point)
- **Services**: ollama (with ollama-rocm, models: gemma4, qwen3-coder-next), open-webui
- **nix-ld extended**: ROCm runtime libraries
- **Packages**: rocminfo, rocm-smi, pixi

**homeManager**: Session environment variables for GPU.

---

### `den.aspects.lemonade` (NixOS)

AMD NPU support via `nix-amd-ai` input:
- `enableNPU = true`, `enableLemonade = true`
- `enableVulkan = true`, `enableROCm = true`
- Adds user to `video` and `render` groups

---

### `den.aspects.stable-nixpkgs` (NixOS + homeManager)

Provides `pkgs.stable` overlay using the pinned `nixpkgs-stable` (nixos-25.11) channel alongside main `nixpkgs-unstable`.

---

### `den.aspects.local-pkgs` (NixOS + homeManager)

Overlay providing `pkgs.allium-tools` (allium CLI from `juxt/allium-tools` v3.2.3).

---

### `den.aspects.mosqueteiro` (User-level)

**homeManager**:
- **Session**: `EDITOR=nvim`
- **Shell**: zsh with vi mode, autosuggestions, syntax highlighting, starship prompt, fzf, zoxide
- **Git**: user name/email configured
- **Nixpkgs**: `allowUnfree = true`
- **User packages**: brave, vim, neovim (stable), nil, nixd, python314, nodejs_24, go, ripgrep, gh, tree, devenv, pandoc, poppler-utils, nerd-fonts.daddy-time-mono, wezterm, opencode, bitwarden-desktop, signal-desktop, discord

**Includes**:
- `den.provides.define-user` — built-in: creates user account
- `den.provides.primary-user` — built-in: marks as primary user
- `den.provides.user-shell "zsh"` — built-in: sets shell
- `den.aspects.stable-nixpkgs`

---

## Aspect Inclusion DAG

```
frameworkDesktop
  |-- den.provides.hostname
  |-- den.aspects.gaming
  |-- den.aspects.ai
  |-- den.aspects.lemonade
  |-- den.aspects.local-pkgs

mosqueteiro
  |-- den.provides.define-user
  |-- den.provides.primary-user
  |-- den.provides.user-shell "zsh"
  |-- den.aspects.stable-nixpkgs
```

---

## Pinned Dependencies

All external dependencies are pinned via `npins/sources.json`:

| Pin | Source | Purpose |
|-----|--------|---------|
| `nixpkgs` | nixpkgs-26.11 (unstable) | Main package source |
| `nixpkgs-stable` | nixos-25.11 | Stable overlay |
| `den` | `vic/den` | den framework |
| `import-tree` | `vic/import-tree` | Auto-imports modules/ tree |
| `with-inputs` | `vic/with-inputs` | Flake-like inputs without flakes |
| `home-manager` | `nix-community/home-manager` | User-level config |
| `nixos-hardware` | `NixOS/nixos-hardware` | Framework Desktop hardware module |
| `flake-aspects` | `vic/flake-aspects` | den's aspect system library |
| `nix-amd-ai` | `noamsto/nix-amd-ai` | AMD NPU/AI (lemonade) support |
| `nix-amd-ai-flake-parts` | (follows) | Transitive dep resolution |
| `nix-amd-ai-nix-darwin` | (follows) | Transitive dep resolution |
| `nix-amd-ai-nixpkgs-lib` | (follows) | Transitive dep resolution |

The three "follows" pins exist solely to resolve `nix-amd-ai`'s transitive dependencies to single pinned versions.

---

## Key Files

| File | Purpose |
|------|---------|
| `default.nix` | Entry point — wires npins, with-inputs, import-tree |
| `modules/den.nix` | Central configuration — hosts, users, all aspects |
| `modules/_nixos/configuration.nix` | Legacy NixOS config (being migrated into aspects) |
| `modules/_nixos/hardware-configuration.nix` | Auto-generated hardware scan (do not edit) |
| `npins/sources.json` | Pinned dependency manifest (do not edit manually) |
| `nix-system.allium` | Allium specification — domain-level architectural description |
| `pkgs/allium-tools/default.nix` | Custom package definition |
| `modules/starship.toml` | Starship prompt theme configuration |

### `modules/_nixos/configuration.nix`

A traditional NixOS configuration that serves as a **legacy bucket** — config that hasn't yet been migrated into aspects lives here. Currently contains:
- Network manager
- Firefox
- Kate editor
- User creation and group membership

---

## Build & Apply

```bash
# Validate configuration (build without switching)
nixos-rebuild build --file . -A nixosConfigurations.frameworkDesktop

# Apply configuration to running system (requires sudo)
sudo nixos-rebuild switch --file . -A nixosConfigurations.frameworkDesktop

# Evaluate config (type check)
nix eval . --attr nixosConfigurations.frameworkDesktop.config.system.build.toplevel
```

Shell aliases (in zsh):
- `den-build` → `nixos-rebuild build ...`
- `den-test` → `nixos-rebuild test ...`
- `den-suwitch` → `sudo nixos-rebuild switch ...`

---

## Debugging

- **Type checking**: `nix eval . --attr nixosConfigurations.frameworkDesktop.config.networking.hostName`
- **Trace context**: Add `builtins.trace` to see available context variables
- **REPL**: `nix repl` for interactive exploration
- **Formating**: `nix fmt` for code formatting, `nil check` for linting

See the [den debug guide](https://den.oeiuwq.com/guides/debug/) for more.
