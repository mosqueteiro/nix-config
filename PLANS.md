# NixOS Configuration Plans

## Current System
- **Hardware**: Framework Desktop with AMD Ryzen AI Max+ 395 (32-core)
- **GPU**: AMD Radeon 8060S Graphics (integrated, RDNA 3.5 / Strix Point)
- **Kernel**: 6.18.19 (well above recommended 6.14+)
- **Desktop**: KDE Plasma 6 on Wayland

---

## Tasks

### Desktop
- [ ] [KDE Plasma ricing (colors, theme, widgets)](#kde-plasma-ricing)
- [ ] [Nerd font system-wide (not just wezterm)](#plan-user-wide-nerd-font)

### Development
- [-] [Fix Wezterm lag on Plasma 6 + Wayland](#plan-fix-wezterm-lag-on-plasma-6-wayland)
- [ ] [add Displaylink support (KDE Plasma + Wayland)](#plan-displaylink-support-kde-plasma-wayland) 

### Games
- [ ] [Minecraft management (Prism Launcher or nix module)](#plan-minecraft-management)

### Advanced
- [x] [AI Tooling (Ollama, Lemonade, MAX, Mojo)](#plan-ai-tooling-ollama-lemonade-max-mojo)
- [x] [Unlock system with YubiKey](#plan-yubikey-system-unlock)
- [ ] [Cosmic desktop experiment](#cosmic-desktop-experiment)
- [ ] [Containers & jails with Nix](#plan-containers-and-jails-with-nix)
- [ ] [Explore Cachy-optimized Linux kernel](#plan-cachy-optimized-kernel)

### NixOS Housekeeping
- [ ] [Investigate how often to update nixpkgs](#investigate-how-often-to-update-nixpkgs)
- [ ] [Try nh tool](#other-nix-tools-to-try)
- [ ] [Try nixos-facter](#other-nix-tools-to-try)
- [x] [Migrate remaining configuration.nix into den.nix aspects](#config-migration-and-module-evaluation)
- [ ] [Evaluate den modules structure and when to break things up](#config-migration-and-module-evaluation)

---

## Completed
### Core Setup
- [x] Framework hardware support
- [x] Set system editor to vim
- [x] Set user editor to nvim
- [x] Enable fwupd for firmware updates

### Development
- [x] Reset onboard security decrypt key
- [x] [Fix Neovim LSP errors (nix-ld)](#plan-fix-neovim-lsp-errors-dynamic-binaries)
- [x] [Pin Neovim to stable while keeping unstable base](#plan-pin-neovim-to-stable-while-keeping-unstable-base)

### Connectivity
- [x] Enable Bluetooth
- [x] Test Bluetooth devices (headphones, keyboard, mouse)

### Desktop
- [x] [Wallpaper customization](#desktop-wallpaper)
- [x] [Signal Desktop](#plan-signal-desktop)

### Gaming
- [x] Enable gamescope
- [x] Enable Steam

### Shell (Zsh)
- [x] [Starship prompt](#starship-prompt)
- [x] [Aliases via home-manager](#plan-local-aliases-and-functions)
- [x] Vim mode (vi keybindings)
- [x] Functions via home-manager (if needed)

---

## Plan: Gaming Support

### Completed
- [x] Enable gamescope for latency/VRR improvements
- [x] Enable Steam

### Future
- Add Lutris (game launcher) - skipped for now
- Add ProtonUp-Qt (for ProtonGE) - not needed for current games
- Consider nix-gaming for custom ProtonGE builds if needed


## Plan: Bluetooth Support

### Completed
- [x] Enable Bluetooth (`hardware.bluetooth.enable = true`)
- [x] Test actual Bluetooth devices (headphones, keyboard, mouse, etc.)

## Plan: Local Aliases and Functions

### Completed
- [x] Aliases via home-manager `programs.zsh.shellAliases`
- [x] Vim mode via `programs.zsh.initContent` with `bindkey -v`

### Future
- Functions via home-manager (if needed)

### Notes
User-specific aliases are in `modules/den.nix` under `den.aspects.mosqueteiro.homeManager.programs.zsh.shellAliases`. Rebuild after editing.


## Plan: Zsh Configuration

### Starship Prompt
Add a nicer shell prompt using starship (cross-shell, fast, customizable).

**Implementation:**
1. Add starship to home-manager user packages: `pkgs.starship`
2. Configure in home-manager:
   ```nix
   programs.starship = {
     enable = true;
     settings = {
       # optional custom config
     };
   };
   ```


## Plan: Desktop Customization (Rice)

### Desktop Wallpaper
Set a nice desktop wallpaper for KDE Plasma.

**Options:**
- Use nix to manage wallpaper (via home-manager `programs.plasma6.desktopTheme`)
- Keep wallpaper locally and configure via Plasma settings
- Find a good open source/anime/art wallpaper to bundle in nix config

### KDE Plasma Ricing
Customize the desktop experience:
- Color scheme / GTK theme
- Window decorations (KDE Aurorae or custom)
- Plasma widgets and panels
- Task manager / dock (krunner, latenf, etc.)
- System tray icons
- Login screen (SDDM theme)

### Cosmic Desktop Experiment
Try System76's Cosmic desktop environment (written in Rust, Alpha status).

**Note:** Cosmic is still in early development. Could be an interesting experiment but may not be production-ready.

**Implementation:**
```nix
# Only if cosmic is available in nixpkgs and stable enough
services.desktopManager.cosmic.enable = true;
# Disable plasma in favor of cosmic
services.desktopManager.plasma6.enable = false;
```


## Plan: User-Wide Nerd Font

### Problem
Nerd font (Daddy Time Mono) is configured in wezterm.lua but not applied to the KDE Plasma desktop (file manager, terminal titles, etc.).

### Current State
- Font already installed via home-manager: `pkgs.nerd-fonts.daddy-time-mono`
- Working in wezterm (configured in wezterm.lua)

### Solution
Configure font in home-manager for KDE Plasma:

```nix
home-manager.users.mosqueteiro = {
  fonts.fontconfig.enable = true;
  fonts.fontconfig.defaultFonts = {
    monospace = [ "Daddy Time Mono Nerd Font" ];
    sansSerif = [ "Inter" ];  # or preferred
  };
};
```

This makes the font available to all GTK/Qt applications in the desktop environment.


## Plan: Fix Neovim LSP Errors (Dynamic Binaries)

### Problem
Mason.nvim installs pre-compiled LSP binaries (lua-language-server, marksman, etc.) that expect `/lib64/ld-linux-x86-64.so.2`. NixOS stores the dynamic linker in the nix store, causing "Could not start dynamically linked executable" errors.

### Solution: Enable nix-ld
Add to nixos config:
```nix
programs.nix-ld.enable = true;
```

This runs at the system level and makes mason-installed LSPs work without modifying `~/.config/nvim`.

### Implementation
1. Add `programs.nix-ld.enable = true;` to `den.aspects.frameworkDesktop.nixos` in `modules/den.nix`
2. Run: `sudo nixos-rebuild switch`


## Plan: Pin Neovim to Stable While Keeping Unstable Base

### Problem
`nixpkgs-unstable` moved Neovim to `0.12.x`, but local config targets `0.11.x` for now.

### Solution
- Keep default `nixpkgs` on unstable for hardware/ROCm freshness.
- Add `nixpkgs-stable` channel (`nixos-25.11`) in `npins`.
- Expose stable packages through `den.aspects.stable-nixpkgs` as `pkgs.stable`.
- Use `pkgs.stable.neovim` in user packages.

### Result
- Neovim resolves to `0.11.7`.
- System remains on unstable for the rest of packages.


## Plan: Fix Wezterm Lag on Plasma 6 + Wayland

### Problem
Wezterm fails to redraw/render output until keyboard or mouse input is received. Known issue with **Plasma 6 + Wayland** - affects both NVIDIA and AMD GPUs (wezterm#5284, wezterm#3126).

**Symptoms:**
- Window appears frozen
- Output catches up when any key is pressed (e.g., Alt key triggers refresh without adding characters)
- Works fine after restarting

**Root cause:** Wayland explicit sync protocol interaction with compositor - NOT GPU-specific

### Solutions

**Option A: Try WebGpu renderer (Recommended for AMD)**
Keep Wayland enabled but switch renderer:
```lua
config.front_end = "WebGpu"
```

**Option B: Force X11 mode** (most reliable)
```lua
config.enable_wayland = false;
```

**Option C: Try OpenGL explicitly**
```lua
config.front_end = "OpenGL";
```

### Implementation
Edit `~/.config/wezterm/wezterm.lua` to add:
```lua
config.front_end = "WebGpu"  -- or enable_wayland = false
```

### Testing Order
1. Try Option A first (WebGpu + Wayland)
2. If still laggy, try Option B (X11 mode)

## Plan: DisplayLink Support (KDE Plasma + Wayland)

### Current Config Analysis
- `allowUnfree = true` is provided by `den.aspects.allow-unfree` in `modules/den.nix`
- `services.xserver.enable = true` already set (required for DisplayLink)
- `services.desktopManager.plasma6.enable = true` already set

### Implementation

1. **Add displaylink package** to `environment.systemPackages`:
   ```nix
   environment.systemPackages = with pkgs; [
     neovim
     displaylink
   ];
   ```

2. **Enable evdi kernel module**:
   ```nix
   boot = {
     extraModulePackages = [ config.boot.kernelPackages.evdi ];
     initrd.kernelModules = [ "evdi" ];
   };
   ```

3. **Set KWIN environment variable**:
   ```nix
   environment.variables = {
     KWIN_DRM_PREFER_COLOR_DEPTH = "24";
   };
   ```

4. **Create systemd service**:
   ```nix
   systemd.services.displaylink-server = {
     enable = true;
     requires = [ "systemd-udevd.service" ];
     after = [ "systemd-udevd.service" ];
     wantedBy = [ "multi-user.target" ];
     serviceConfig = {
       Type = "simple";
       ExecStart = "${pkgs.displaylink}/bin/DisplayLinkManager";
       User = "root";
       Group = "root";
       Restart = "on-failure";
       RestartSec = 5;
     };
   };
   ```

### Notes
- No prefetch step needed - `den.aspects.allow-unfree` already enables unfree packages
- The systemd service approach is specific to KDE Plasma Wayland
- After rebuild, plug in your DisplayLink device - it should be detected automatically

## Plan: Minecraft Management

### Background
Previously used Prism Launcher to manage multiple Minecraft instances with separate plugins, mod packs, resource packs, and worlds. Goal is to explore Nix-based management or continue using Prism.

### Options

**Option A: Prism Launcher (Quick Start)**
- Available in nixpkgs: `pkgs.prismlauncher`
- Works immediately, familiar workflow
- Manages instances, mods, modpacks, worlds via GUI
- Trade-off: Not nix-managed, some manual updating

**Option B: Nix Module for Minecraft (Long-term)**
Build a custom nix module/flake that handles:
- Multiple isolated Minecraft instances (Java edition)
- Mod packs (via overrides or fetch from CurseForge/Modrinth)
- Resource packs
- Game worlds (separate per instance)
- Server instances (can run on same machine or remote)
- Version updates via nix

**Potential Architecture:**
```nix
# Conceptual - not yet built
den.aspects.minecraft = {
  instances = {
    survival = {
      version = "1.20.4";
      modPack = ./modpacks/survival;
      java = pkgs.jdk17;
    };
    creative = {
      version = "1.20.4";
      modPack = ./modpacks/creative;
    };
  };
  servers = {
    survival = {
      port = 25565;
      ops = [ "player1" ];
      world = "survival";
    };
  };
};
```

**Option C: Hybrid**
Use Prism for desktop gameplay + nix for server instances only.

### Research Tasks
1. Check what's available in nixpkgs for Minecraft
2. Look for existing nix modules/flakes (search: minecraft-deploy, nix-minecraft)
3. Evaluate effort to build custom module vs. using Prism
4. Consider portability: can nix config be used on homelab/cloud for servers?

### Recommended Next Steps
1. Start with Prism Launcher (Option A) for immediate play
2. Research existing nix solutions in parallel
3. Decide whether to invest in custom module (Option B) based on research


---

## NixOS Housekeeping

### Investigate: How Often to Update nixpkgs?

Research the trade-offs between updating frequently vs. conservatively. Document best practices for desktop users.

**Tasks:**
- Research recommendations from NixOS community
- Document pros/cons of weekly vs. monthly vs. as-needed updates
- Determine default recommendation for new users

### Other Nix Tools to Try

**nh** — Modern NixOS helper that replaces `nixos-rebuild` with better UX ([github](https://github.com/DeterminateSystems/nh)).
- [ ] Add `nh` to system packages or as a flake input
- [ ] Compare features to current `nixos-rebuild` + `den-suwitch` workflow
- [ ] Test: `nh os switch`, `nh os build`, `nh os test`

**nixos-facter** — Hardware report generator by Determinate Systems, alternative to `nixos-generate-config` ([github](https://github.com/DeterminateSystems/nixos-facter)).
- [ ] Run `nixos-facter` on this machine to generate a hardware report
- [ ] Evaluate whether the output can replace or supplement `hardware-configuration.nix`
- [ ] Check for ongoing maintenance and community adoption

### Config Migration & Module Evaluation

**Migrate remaining configuration.nix into den.nix aspects**
- [x] Audit the legacy `configuration.nix` contents
- [x] Move locale settings into `den.aspects.locale-denver`
- [x] Move desktop applications into `den.aspects.desktop-apps`
- [x] Move unfree package policy into `den.aspects.allow-unfree`
- [x] Move networking and `system.stateVersion` into `den.aspects.frameworkDesktop`
- [x] Move the generated hardware module to `modules/hosts/framework-desktop/_hardware/`
- [x] Remove the legacy `configuration.nix`

**Evaluate den modules structure**
- [ ] Review current `modules/` layout vs. what's in `modules/den.nix`
- [ ] Assess whether `modules/den.nix` is becoming too large/hard to navigate
- [ ] Consider splitting aspects into separate files under `modules/` (e.g., `modules/desktop/`, `modules/hosts/`, or future feature directories)
- [ ] Document decision criteria: when does an aspect warrant its own file? (e.g., >50 lines, logically independent, optional feature)
- [ ] Evaluate `import-tree` for flake-like module organization without flakes

---

## Plan: YubiKey System Unlock

### Completed
- [x] Enroll YubiKey as FIDO2 LUKS unlock method (PIN + touch)
- [x] Verified FIDO2 unlock path (boot with YubiKey, PIN, touch)
- [x] Verified TPM2 fallback still works
- [x] Verified passphrase slot remains available

### Approach: Native systemd-initrd FIDO2 (not ykfde/challenge-response)
- `ykfde` / `yubikey-full-disk-encryption` are **not available** in pinned nixpkgs
- `boot.loader.systemd-boot.yubikeySupport` is **not a valid option**
- Native `systemd-cryptenroll` FIDO2 is supported and is the modern path

### Configuration (`modules/den.nix`, `den.aspects.frameworkDesktop.nixos`)
```nix
boot.initrd.systemd = {
  enable = true;
  tpm2.enable = true;
  fido2.enable = true;
};

boot.initrd.luks.devices."luks-73982fd7-f423-475c-972e-83a2f8de521a".crypttabExtraOpts = [
  "fido2-device=auto"
];

security.tpm2.enable = true;
```

The LUKS device path (`device = ...`) stays in the generated `modules/hosts/framework-desktop/_hardware/hardware-configuration.nix`; only the unlock policy lives in the host aspect.

### Enrollment (one-time, already done)
```bash
sudo systemd-cryptenroll \
  --fido2-device=auto \
  --fido2-with-client-pin=yes \
  --fido2-with-user-presence=yes \
  /dev/disk/by-uuid/73982fd7-f423-475c-972e-83a2f8de521a
```

- Added a new FIDO2 keyslot (slot 2); existing TPM2 and passphrase slots preserved
- Backup LUKS header first (`cryptsetup luksHeaderBackup`) if repeating on another machine
- YubiKey must support FIDO2 `hmac-secret`

### Testing Notes
- At boot: enter YubiKey PIN, then **touch the key** (no visible prompt appears — wait for the key's LED)
- No visible "touch your key" prompt; after PIN entry just touch the key once
- To force FIDO2-only test (optional): temporarily set `tpm2.enable = false`, `nixos-rebuild boot`, reboot with YubiKey, then restore and `switch`
- TPM2 (PCRs 0+7) invalidates only on BIOS/firmware or Secure Boot policy changes

---

## Plan: Cachy-Optimized Linux Kernel

### Goal
Replace the generic Linux kernel with a CachyOS-optimized build for improved performance on AMD Ryzen hardware.

### Background
- **CPU**: AMD Ryzen AI Max+ 395 (32-core, Zen 5)
- **Current kernel**: 6.18.19 (generic nixpkgs unstable)
- CachyOS kernels apply scheduler, compiler, and config optimizations (BORE scheduler, `-O3` / `-march=znver5`, tickless, etc.)

### Options

**Option A: nixpkgs `linuxPackages_cachyos`**
- Available in nixpkgs: `pkgs.linuxPackages_cachyos`
- Pre-built, includes optimizations for modern x86_64
- Easiest to try first

**Option B: Custom kernel with `linuxKernel`**
```nix
boot.kernelPackages = pkgs.linuxPackages_cachyos;
```

**Option C: Build custom config on top of latest kernel**
- Start from `pkgs.linuxPackages_latest` and apply CachyOS patches/config manually
- More maintenance, marginal gains over Option A

### Risks & Considerations
- Need to verify compatibility with AMD GPU (Radeon 8060S / amdgpu driver)
- Must support btrfs + LUKS + systemd-initrd
- Custom modules (evdi for DisplayLink, ZFS) need kernel compatibility
- ROCm/Ollama may need testing with non-generic kernel

### Tasks
- [ ] Test `pkgs.linuxPackages_cachyos` on this hardware
- [ ] Verify amdgpu, btrfs, LUKS, systemd-initrd all work
- [ ] Run benchmarks (kernel compile, ollama inference, gaming) vs. generic kernel
- [ ] Check if any nixpkgs packages break due to kernel version mismatch
- [ ] Document performance uplift (if any) and stability

---

## Plan: AI Tooling (Ollama, Lemonade, MAX, Mojo)

### Completed
- [x] Enable native NixOS ROCm support
- [x] Create a unified `den.aspects.ai` aspect to manage these tools
- [x] Ollama service configured and running
- [x] Open-WebUI service configured and running

### AI Tools
- **Ollama**: Natively supported via `services.ollama`. Configured with `package = pkgs.ollama-rocm;`.
- **Open-WebUI**: Natively supported via `services.open-webui`.
- **Modular (MAX & Mojo)**: Managed via `pixi` (which replaces `magic`). Since `pixi` downloads pre-compiled binaries expecting a standard Linux filesystem, we use `programs.nix-ld` globally to allow these binaries to run anywhere.
  - *Alternative (Strict Isolation)*: Drop a `flake.nix` with `buildFHSUserEnv` into each project folder to create a temporary FHS sandbox.
- **Lemonade Server**: Currently pending NixOS merge (PR #498314). We will build it from source or via the PR branch in the future.

### Implementation Details
We combined all these into a single `den.aspects.ai` aspect for ease of use, with the understanding that we can use Context-Driven Dispatch (`{ host, ... }:`) to selectively apply NVIDIA vs. AMD packages if a new host is added.


## Plan: Signal Desktop

### Background
Add Signal Desktop to home-manager packages for linking with mobile phone.

### Implementation

1. Add `pkgs.signal-desktop` to `home.packages` in `modules/den.nix`:
   ```nix
   home.packages = [
     # ... existing packages
     pkgs.signal-desktop
   ];
   ```

2. Rebuild: `sudo den-suwitch`

3. Link to mobile:
   - Launch Signal Desktop
   - Click "Link a Device"
   - Scan QR code with Signal mobile app

### Notes
- Signal stores data in `~/.config/Signal` (persists with btrfs/LUKS)
- On KDE Plasma, Signal should auto-use KWallet for secrets
- If keyring issues occur, may need `--password-store=kwallet6` in desktop entry
- nixpkgs build includes proper `.desktop` file


## Plan: Containers and Jails with Nix

### Goal
Explore containerization and isolation technologies available on NixOS — running OCI/Docker images, building lightweight containers with Nix, and using NixOS's built-in container/jail primitives.

### Areas to Explore

**1. Running Existing OCI/Docker Images**
- [ ] Evaluate Docker vs. Podman on NixOS (daemonless, rootless, nix integration)
- [ ] Configure `virtualisation.docker.enable` or `virtualisation.podman.enable`
- [ ] Test pulling and running generic OCI images from Docker Hub/GHCR

**2. Building Containers with Nix**
- [ ] Explore `pkgs.dockerTools.buildImage` — build OCI images entirely from nix derivations (no Dockerfile)
- [ ] Explore `pkgs.ociTools` / `nix2container` for more efficient layer caching
- [ ] Build a minimal container image for a simple service (e.g., nginx, a Rust binary)
- [ ] Compare image sizes: Nix-built vs. traditional Dockerfile-built

**3. NixOS Containers (Declarative Jails)**
- [ ] Explore `containers` option in NixOS — declarative, systemd-nspawn based
- [ ] Configure a declarative container with its own NixOS config
- [ ] Test networking: bridge, NAT, host networking, veth pairs
- [ ] Use cases: isolated dev environments, service jails (PostgreSQL, Redis), legacy software

**4. NixOS MicroVMs**
- [ ] Explore `microvm.nix` (nixpkgs-based lightweight VMs)
- [ ] Compare to containers: stronger isolation (KVM), but more overhead
- [ ] Evaluate for untrusted workloads or full environment simulation

**5. Environment Isolation (Not Full Containers)**
- [ ] Explore `pkgs.buildFHSUserEnv` — Create FHS-compatible sandboxes for binaries that expect standard Linux filesystem layout (already partially used for nix-ld)
- [ ] Explore `nix-shell --pure` and `pkgs.mkShell` for reproducible dev environments
- [ ] Evaluate `bubblewrap` (`pkgs.bubblewrap`) for lightweight, unprivileged sandboxing of individual commands

**6. OCI Container Building Pipeline**
- [ ] Design a reusable Nix expression to build and optionally push OCI images to a registry
- [ ] Integrate with `npins` for pinning base images
- [ ] Explore multi-arch builds (x86_64 + aarch64)

### Configuration Location
- System-wide container config: `virtualisation.*` options in `modules/den.nix` (nixos aspect)
- Container definitions: `containers.*` in nixos aspect
- Image building: helper functions in a new `modules/containers/` directory or an aspect

### Notes
- Podman is preferred over Docker on NixOS for rootless, daemonless operation
- `dockerTools.buildImage` produces layered OCI images without needing Docker at build time
- `containers` is a built-in NixOS module — no extra software needed for declarative jails
- `buildFHSUserEnv` is useful for running binaries that expect standard paths (e.g., game launchers, prebuilt SDKs) — can be an alternative to `nix-ld` for specific packages
