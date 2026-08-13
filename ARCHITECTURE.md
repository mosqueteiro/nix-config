# Architecture

This document describes the structure and design of this NixOS/home-manager configuration repository, which uses the [den](https://den.oeiuwq.com/) framework in the no-flake template.

## System Overview

| Property | Value |
|----------|-------|
| Machine | Framework Desktop (AMD Ryzen AI Max+ 395, 32-core) |
| GPU | AMD Radeon 8060S (RDNA 3.5 / Strix Point / gfx1151) |
| RAM | 128 GB |
| Storage | Single NVMe, LUKS encrypted, btrfs (subvolumes: `@`, `@home`) |
| Boot | UEFI, systemd-boot, TPM2 passwordless unlock + FIDO2 YubiKey |
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
|   |-- den.nix                         # Central config: hosts, users, aspect definitions
|   |-- starship.toml                   # Starship prompt theme
|   |-- desktop/
|   |   |-- desktop.nix                 # Desktop, CLI, and developer-tool aspects
|   |-- hosts/
|       |-- framework-desktop/
|           |-- README.md               # Machine-specific hardware and unlock docs
|           |-- _hardware/
|               |-- hardware-configuration.nix # Auto-generated hardware scan
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
  |-- den.nix              # Host/user declarations and aspect definitions
  |-- desktop/desktop.nix  # Additional aspect definitions
  |-- hosts/                # Host-specific documentation and modules
       |
       |-- den.nix imports den.flakeModule
       |-- declares: host = frameworkDesktop, user = mosqueteiro
       |-- defines and composes aspects
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
4. **Module evaluation**: `import-tree` imports the normal `.nix` modules under `modules/`. These modules import the den flake module, declare the host and user, and define or extend aspects. Underscore-prefixed directories such as `_hardware` are kept for explicitly imported host modules.
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
  includes = [ den.aspects.developer-tools den.provides.primary-user ];
  nixos = { ... };
};
```

---

## Aspects Defined

### `den.aspects.frameworkDesktop` (Host-level)

The main host aspect. Includes all other host aspects.

**NixOS**:
- **Imports** `modules/hosts/framework-desktop/_hardware/hardware-configuration.nix` + `nixos-hardware.framework-desktop-amd-ai-max-300-series`
- **Display**: SDDM (Numlock on) → KDE Plasma 6
- **Boot**: systemd-boot, TPM2, initrd systemd
- **Networking**: NetworkManager
- **Memory**: zramSwap
- **Firmware**: fwupd
- **Sound**: PipeWire (ALSA + PulseAudio compat)
- **Bluetooth**: enabled
- **Direnv**: enabled with nix-direnv
- **nix-ld**: enabled (dynamic binary compatibility)
- **Nix**: flakes + nix-command, `nix-amd-ai.cachix.org` substituter
- **State version**: `25.11`
- **System packages**: provided by the common CLI, desktop-apps, developer-tools, and GPU aspects; includes vim, neovim, git, gcc, gnumake, fd, sqlite, npins, nixfmt, ghostscript, tectonic, imagemagick, mermaid-cli, unzip, wget, fastfetch, btop-rocm, allium-tools, rocminfo, rocm-smi, pixi, Brave, and Qalculate! Qt

**Includes**:
- `den.provides.hostname` — built-in: sets hostname from host config
- `den.aspects.locale-denver`
- `den.aspects.allow-unfree`
- `den.aspects.desktop` — PipeWire, Bluetooth, common CLI tools, and desktop applications
- `den.aspects.developer-tools` — development tools and local packages
- `den.aspects.gaming`
- `den.aspects.modular-ai` — Modular MAX/Mojo tooling
- `den.aspects.ollama` — Ollama and Open WebUI services
- `den.aspects.lemonade`
- `den.aspects.local-pkgs`

---

### `den.aspects.gaming` (NixOS)

- `programs.gamescope.enable = true`
- `programs.steam.enable = true`

---

### `den.aspects.desktop` (NixOS)

Defined in `modules/desktop/desktop.nix`:

- Includes `common-cli` and `desktop-apps`
- Enables PipeWire with ALSA, 32-bit ALSA, and PulseAudio compatibility
- Disables PulseAudio and enables realtime scheduling through `rtkit`
- Enables Bluetooth

### `den.aspects.desktop-apps` (NixOS)

Defined in `modules/desktop/desktop.nix`:

- Includes `den.aspects.allow-unfree` for Brave
- Firefox enabled through `programs.firefox`
- Brave installed as a system package and set as the default browser
- Qalculate! Qt installed as a system package

---

### `den.aspects.developer-tools` (NixOS)

Defined in `modules/desktop/desktop.nix`:

- Includes `common-cli` and `local-pkgs`
- Installs Neovim, Git, GCC, GNU Make, Ghostscript, Tectonic, ImageMagick, Mermaid CLI, and SQLite
- Installs the local `allium-tools` package

### `den.aspects.common-cli` (NixOS)

Defined in `modules/desktop/desktop.nix`:

- Sets the system editor to `vim`
- Installs common CLI tools: fd, fastfetch, vim, unzip, wget, nixfmt, and npins

---

### `den.aspects.allow-unfree` (NixOS + homeManager)

Enables `nixpkgs.config.allowUnfree` for the package sets used by the host and user configurations.

---

### `den.aspects.locale-denver` (NixOS)

Configures the `America/Denver` timezone and `en_US.UTF-8` locale settings.

---

### `den.aspects.amd-gpu` (NixOS)

Defined in `modules/amd-gpu.nix`:

- Enables graphics support with 32-bit compatibility
- Enables AMDGPU OpenCL and the ROCm ICD
- Installs `rocminfo` and `rocm-smi`

### `den.aspects.strix-halo-gpu` (NixOS + homeManager)

Defined in `modules/amd-gpu.nix`:

- Includes `den.aspects.amd-gpu`
- Sets `HSA_OVERRIDE_GFX_VERSION="11.5.1"` and `HCC_AMDGPU_TARGET="gfx1151"` for Strix Point/Halo GPUs
- Exposes the same overrides through the home-manager session environment

### `den.aspects.modular-ai` (NixOS)

**Includes**: `den.aspects.strix-halo-gpu`

- Installs `pixi` for Modular MAX and Mojo tooling
- Extends `nix-ld` with the C compiler, zlib, ROCm runtime, HIP, and OpenCL libraries required by precompiled Pixi environments

### `den.aspects.ollama` (NixOS)

**Includes**: `den.aspects.strix-halo-gpu`

- Enables Ollama with the `ollama-rocm` package
- Loads `gemma4:e4b`, `gemma4:26b`, `gemma4:31b`, and `qwen3-coder-next`
- Enables Open WebUI

### `den.aspects.nix-amd-ai` (NixOS)

- Imports the `nix-amd-ai` NixOS module
- Enables the AMD NPU, Vulkan, and ROCm support
- Adds the primary user to the `video` and `render` groups

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

**User class**:
- **User metadata**: description set to `Mosqueteiro`

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
- `den.aspects.allow-unfree`
- `den.aspects.stable-nixpkgs`

---

## Aspect Inclusion DAG

```
frameworkDesktop
  |-- den.provides.hostname
  |-- den.aspects.locale-denver
  |-- den.aspects.allow-unfree
  |-- den.aspects.desktop
  |   |-- den.aspects.common-cli
  |   |-- den.aspects.desktop-apps
  |       |-- den.aspects.allow-unfree
  |-- den.aspects.developer-tools
  |   |-- den.aspects.common-cli
  |   |-- den.aspects.local-pkgs
  |-- den.aspects.gaming
  |-- den.aspects.modular-ai
  |   |-- den.aspects.strix-halo-gpu
  |       |-- den.aspects.amd-gpu
  |-- den.aspects.ollama
  |   |-- den.aspects.strix-halo-gpu
  |       |-- den.aspects.amd-gpu
  |-- den.aspects.lemonade
  |   |-- den.aspects.nix-amd-ai
  |-- den.aspects.local-pkgs

mosqueteiro
  |-- den.provides.define-user
  |-- den.provides.primary-user
  |-- den.provides.user-shell "zsh"
  |-- den.aspects.allow-unfree
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
| `modules/den.nix` | Central configuration — hosts, users, and shared aspects |
| `modules/desktop/desktop.nix` | Desktop, CLI, and developer-tool aspects |
| `modules/amd-gpu.nix` | Generic AMD GPU and Strix Halo GPU aspects |
| `modules/hosts/framework-desktop/_hardware/hardware-configuration.nix` | Auto-generated hardware scan (do not edit) |
| `modules/hosts/framework-desktop/README.md` | Framework Desktop hardware and unlock documentation |
| `npins/sources.json` | Pinned dependency manifest (do not edit manually) |
| `nix-system.allium` | Allium specification — domain-level architectural description |
| `pkgs/allium-tools/default.nix` | Custom package definition |
| `modules/starship.toml` | Starship prompt theme configuration |

### Host-specific hardware module

The generated hardware module lives at `modules/hosts/framework-desktop/_hardware/hardware-configuration.nix` and is explicitly imported by `den.aspects.frameworkDesktop.nixos`. It contains filesystem, initrd, kernel-module, and platform-detection settings generated by `nixos-generate-config` and should not be edited manually.

---

## Build & Apply

```bash
# Validate configuration (build without switching)
nixos-rebuild build --file . -A nixosConfigurations.frameworkDesktop

# Apply configuration to running system (requires sudo)
sudo nixos-rebuild switch --file . -A nixosConfigurations.frameworkDesktop

# Evaluate config (type check)
nix eval --file . nixosConfigurations.frameworkDesktop.config.system.build.toplevel
```

Shell aliases (in zsh):
- `den-build` → `nixos-rebuild build ...`
- `den-test` → `nixos-rebuild test ...`
- `den-suwitch` → `sudo nixos-rebuild switch ...`

---

## Debugging

- **Type checking**: `nix eval --file . nixosConfigurations.frameworkDesktop.config.networking.hostName`
- **Trace context**: Add `builtins.trace` to see available context variables
- **REPL**: `nix repl` for interactive exploration
- **Formatting**: `nix fmt` for code formatting, `nil diagnostics` for linting

See the [den debug guide](https://den.oeiuwq.com/guides/debug/) for more.
