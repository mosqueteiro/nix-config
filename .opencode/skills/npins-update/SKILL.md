---
name: npins-update
description: Use when updating pinned dependencies, upgrading nixpkgs/den/home-manager, bumping state version, or rolling back a failed update.
compatibility: opencode
metadata:
  audience: nix-config
  workflow: npins-dependency-management
---

# npins Update

Each pin (`nixpkgs`, `den`, `home-manager`, etc.) evolves independently. Updating all at once (`npins update`) can pull in multiple breaking changes simultaneously — favor single-pin updates (`npins update den`) unless you're intentionally doing a batch refresh.

The agent can only **build** (validate). Applying the config with `sudo nixos-rebuild switch` is outside the agent's capability — present the command for the user to run.

For the full walkthrough see [`docs/UPGRADE.md`](../../../docs/UPGRADE.md).

## Core Workflow

```bash
# Update a specific pin (preferred)
npins update den

# Update all pins (batch refresh — more risk)
npins update

# Build without switching (validate — agent can run this)
nixos-rebuild build --file . -A nixosConfigurations.frameworkDesktop

# Apply if successful — agent cannot run sudo; present for user
sudo nixos-rebuild switch --file . -A nixosConfigurations.frameworkDesktop
```

## Key Decisions

| Action | When | Steps |
|--------|------|-------|
| Update nixpkgs | Weekly (tracks unstable) | `npins update nixpkgs` → build → present switch for user |
| Update den | Per release | Read [changelog](https://den.oeiuwq.com/releases/) first → `npins update den` → build → present switch for user |
| Bump state version | After switching to a new NixOS release | Update `system.stateVersion` in `modules/_nixos/configuration.nix` AND `den.default.homeManager.home.stateVersion` in `modules/den.nix` |
| Roll back a switch | Boot failure | Select previous generation from systemd-boot menu, or ask user to run `sudo nixos-rebuild switch --rollback` |

## Safety Rails

- **Never edit** `npins/sources.json` or `npins/default.nix` manually — always use `npins` CLI.
- **Check the [den changelog](https://den.oeiuwq.com/releases/)** before updating den — breaking changes in aspect syntax or schema are possible.
- **Don't bump stateVersion until** you've successfully switched on the new release and confirmed everything works.
- **Keep your LUKS passphrase** accessible — TPM unlock may break after firmware updates.

## References

- [`docs/UPGRADE.md`](../../../docs/UPGRADE.md) — full upgrade guide with cadence recommendations, state version procedures, rollback strategies, and post-update checklist
- [den changelog](https://den.oeiuwq.com/releases/)
- [npins](https://github.com/andir/npins)
