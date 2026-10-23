# COSMIC Desktop Trial Plan

Goal: trial COSMIC as a full replacement for KDE Plasma 6 on `frameworkDesktop`,
with both desktops split into their own aspects so switching between them is a
one-line include swap.

## Current state (reviewed)

The desktop stack lives entirely in `den.aspects.frameworkDesktop.nixos`
(`modules/den.nix:39-53`):

- `services.xserver.enable` + `services.xserver.xkb` (X11 basis for Plasma)
- `services.displayManager.sddm` (with Numlock setting)
- `services.desktopManager.plasma6.enable`

Everything else (pipewire, bluetooth, NetworkManager, zram, TPM/FIDO2 LUKS,
gaming/Steam/gamescope, AI stack) is DE-agnostic and does not conflict.
Pinned nixpkgs (unstable, 26.11pre) has both `services.desktopManager.cosmic`
and `services.displayManager.cosmic-greeter` (verified by eval).

## Differences: Plasma 6 -> COSMIC

| Area             | Plasma 6                                | COSMIC                                                                |
|------------------|-----------------------------------------|-----------------------------------------------------------------------|
| Session          | X11/Wayland hybrid, `services.xserver`  | Wayland-native only; module enables XWayland by default. Remove xserver |
| Display manager  | SDDM                                    | `cosmic-greeter` (cannot run two DMs — disable SDDM)                   |
| Config storage   | `~/.config/plasma-*`, `kwinrc`, etc.    | RON files in `~/.config/cosmic/`; no declarative NixOS options yet      |
| Module surface   | Rich option set                         | Module only enables the DE; component config via RON or cosmic-manager  |
| Shortcuts        | KDE shortcuts don't migrate             | Rebuild keybinds in COSMIC settings                                     |

## Gotchas for this trial

1. **Beta quality**: expect panel/applet bugs, apps crashing on monitor wake.
2. **Clipboard**: Wayland focus-based clipboard breaks rapid copy-paste
   (vim macros, clipboard managers). Fix: `COSMIC_DATA_CONTROL_ENABLED = 1`.
3. **Electron apps**: Signal/Discord render too large on Wayland. Fix:
   `ELECTRON_OZONE_PLATFORM_HINT=wayland` (sometimes per-app flags).
4. **Firefox theming**: needs `widget.gtk.libadwaita-colors.enabled = false`
   in about:config for the COSMIC theme to apply.
5. **nixpkgs-unstable churn**: polkit 127 SUID removal breaks cosmic-osd auth
   agent (#473068); SSH agent/keyring path fixed upstream recently. If broken,
   `npins update` usually lands the fix, else overlay-patch.
6. **Do not enable autoLogin**: cosmic-greeter bug sets `XDG_SESSION_TYPE=tty`
   (#557915).
7. **Wezterm**: config forces `enable_wayland = false` (XWayland). Works, but
   if scaling is odd during the trial, flip that line to native Wayland.
8. **KDE leftovers**: `~/.config/plasma-*`, `kwinrc` persist unused — harmless.
9. **Gaming**: Steam/gamescope unaffected (nested sessions).
10. Keyboard layout must be set in COSMIC settings (X11 xkb config doesn't
    apply to Wayland sessions).

### system76-scheduler

System76's `system76-sched` service (the CPU scheduler piece of Pop!_OS). It
watches process exec events via cgroups and dynamically assigns scheduling
classes: short-lived interactive tasks get a latency boost, long-running /
background tasks get deprioritized. Practical effect here: smoother UI when
compiling, building nix, or running ollama/lemonade alongside desktop use.
Userspace autogrouping only — no kernel swap, one-line enable, trivially
removable. Essentially no downside on 16-core Strix Halo.

## Implementation

### 1. New file `modules/desktop/plasma6.nix` — `den.aspects.plasma6-desktop`

Extract the current inline desktop config first and validate the build with
Plasma still active, before touching COSMIC:

```nix
{ den, ... }: {
  den.aspects.plasma6-desktop = {
    nixos = { ... }: {
      services.xserver.enable = true;
      services.xserver.xkb = {
        layout = "us";
        variant = "";
      };
      services.displayManager.sddm = {
        enable = true;
        settings.General.Numlock = "on";
      };
      services.desktopManager.plasma6.enable = true;
    };
  };
}
```

Test build: `nixos-rebuild build --file . -A nixosConfigurations.frameworkDesktop`
— config must stay identical-in-effect (same Plasma/SDDM) at this point.

### 2. New file `modules/desktop/cosmic.nix` — `den.aspects.cosmic-desktop`

```nix
{ den, ... }: {
  den.aspects.cosmic-desktop = {
    nixos = { pkgs, ... }: {
      services.desktopManager.cosmic.enable = true;
      services.displayManager.cosmic-greeter.enable = true;

      # Unstable zwlr data-control protocol: clipboard works for
      # background apps (vim macros, clipboard managers).
      environment.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = 1;

      # Interactive-task CPU boost from System76.
      services.system76-scheduler.enable = true;

      # Trim non-core COSMIC apps (core stays, no exclusion warning).
      environment.cosmic.excludePackages = with pkgs; [
        cosmic-edit
        cosmic-reader
        cosmic-player
        cosmic-term   # wezterm is the terminal
      ];
    };
  };
}
```

### 3. Edit `modules/den.nix`

- Remove the inline xserver/sddm/plasma6 block (lines 39–53); note the old
  config now lives in `modules/desktop/plasma6.nix` (step 1).
- Include `den.aspects.cosmic-desktop` in `den.aspects.frameworkDesktop`.
- Everything else untouched (LUKS, TPM, gaming, AI, locale are DE-agnostic).

### 4. Verification

Each step's build fully evaluates the merged configuration — an eval error or
option conflict (e.g. two display managers) fails there. But a build only
validates the closure; nothing desktop-side is *active* until
`sudo den-suwitch`, and the COSMIC session itself only starts at reboot /
next greeter login.

1. After step 1 (Plasma extraction): `den-build` — config unchanged in effect
2. After step 3 (COSMIC swap): `den-build`, then explicitly confirm the
   evaluated values before switching:

   ```bash
   nix eval --file . nixosConfigurations.frameworkDesktop.config.services.displayManager.cosmic-greeter.enable
   # expect: true
   nix eval --file . nixosConfigurations.frameworkDesktop.config.services.displayManager.sddm.enable
   # expect: false
   ```

3. Apply (either form — `nh` adds a package diff + confirmation):
   ```bash
   sudo den-suwitch
   # or: nh os switch -f ~/nix-config nixosConfigurations.frameworkDesktop
   ```
   (System services — greeter, portals, dconf — are activated live at switch
   time)
4. Reboot to actually run the COSMIC session
5. Optional cleanup after settling: `nh clean all --keep 7 --keep-since 14d`

### 5. First-boot checklist

- cosmic-greeter appears, login works
- Audio (pipewire), network (NetworkManager), bluetooth
- Keyboard layout set in COSMIC settings
- Scaling on the Framework display, screenshots, screen lock
- Electron apps (Signal/Discord) scaling — may need OZONE flags
- Wezterm rendering (flip `enable_wayland` if XWayland scaling is off)
- Firefox theme (libadwaita pref if needed)

### 6. Rollback

- **Primary: boot the previous generation from the systemd-boot menu.**
  This is the canonical rollback — the last known-good Plasma system boots as-is.
- **Secondary: swap includes back to `den.aspects.plasma6-desktop` +
  `sudo den-suwitch`.** Note this is a *roll forward* to a freshly built
  Plasma system, not a strict rollback — state (greeter defaults, portal
  choices, `~/.config` side effects created by COSMIC) does not unwind.

### Accepted risks

- Beta-era bugs (panel applets, monitor re-detect crashes)
- Unstable-chase breakage (polkit agent, ssh-agent) on 26.11pre pin
- No autoLogin (cosmic-greeter session-type bug)
