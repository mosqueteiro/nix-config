---
name: npins-update
description: Use when updating pinned dependencies, upgrading nixpkgs/den/home-manager, updating a package to a newer version (e.g. opencode), refreshing dependencies, investigating what an update would bring, or rolling back a failed update.
compatibility: opencode
metadata:
  audience: nix-config
  workflow: npins-dependency-management
---

# npins Update

The agent can only **build** (validate). Applying the config with `sudo nixos-rebuild switch` is outside the agent's capability — present the command for the user to run.

For the full walkthrough see [`docs/UPGRADE.md`](../../../docs/UPGRADE.md).

## Workflow (one pin at a time)

Always work on a **single pin** per cycle. Each pin (`nixpkgs`, `den`, `home-manager`, etc.) evolves independently; updating one at a time isolates breakage and keeps rollbacks simple.

### Step 1 — Investigate and review findings (before touching the pin)

Check the pin's **Pin Version Tracking** entry in [`docs/UPGRADE.md`](../../../docs/UPGRADE.md#pin-version-tracking):

- Read the latest investigation — it may already answer what the update would bring.
- If stale or missing, research what an update would bring **without changing the pin**:
  - Channel pins (`nixpkgs`, `nixpkgs-stable`): check [Repology](https://repology.org/) or [nixpkgs-multiverse](https://nixmultiverse.com/) for the packages we track (listed per pin in UPGRADE.md).
  - Git pins (`den`, `home-manager`, ...): check branch HEAD, release notes, changelog.
- **Overwrite** the pin's **Latest investigation** block with findings (keep the created date, set updated to today). Do this *before* updating so the decision is recorded either way.
- **Present the findings to the user for review before updating** — what versions the update would bring, caveats, and your recommendation. Proceed only on approval.

### Step 2 — Update the single pin

```bash
npins update <pin>        # e.g. npins update nixpkgs
git diff npins/sources.json   # confirm only the intended pin changed
```

### Step 3 — Build to validate (agent can run this)

```bash
nixos-rebuild build --file . -A nixosConfigurations.frameworkDesktop
```

**Run the build in the background** (the shell tool's background option, i.e. `nohup`-style execution). Builds can run far longer than the foreground timeout — e.g. the 2026-10-23 nixpkgs update took ~20 min (ollama-rocm/llama.cpp dominated), and nix-amd-ai updates source-build FastFlowLM/Lemonade. Backgrounding keeps the session responsive and the output still streams to a log you can read while waiting. If nothing else depends on the build, end your turn — you'll be resumed when it finishes; don't poll.

If the build fails, roll back the pin (`git checkout HEAD~1 npins/sources.json` — or the pre-update commit) and record the failure in the investigation block.

### Step 4 — Present the switch command to the user

```bash
sudo nixos-rebuild switch --file . -A nixosConfigurations.frameworkDesktop
```

The user runs this (agent cannot sudo). After switching, walk through the Post-Update Checklist in `docs/UPGRADE.md`.

### Step 5 — Record the outcome

Update the pin's **Latest investigation** block in `docs/UPGRADE.md` with what actually happened (versions landed, breakage, fixes) and refresh the pin's **Updated** date.

## Not part of the workflow

```bash
npins update    # updates ALL pins at once
```

`npins update` with no arguments is a batch refresh: it pulls every pin forward simultaneously, mixing multiple breaking changes into one generation and making rollback attribution impossible. **Do not run it as a routine step.** Only consider it for an intentional, planned full refresh — and even then, prefer stepping through pins individually.

## Key Decisions

| Action | When | Steps |
|--------|------|-------|
| Update nixpkgs | Weekly (tracks unstable) | Investigate → `npins update nixpkgs` → build → present switch for user |
| Update den | Per release | Read [changelog](https://den.oeiuwq.com/releases/) first → `npins update den` → build → present switch for user |
| Roll back a switch | Boot failure | Select previous generation from systemd-boot menu, or ask user to run `sudo nixos-rebuild switch --rollback` |

## Safety Rails

- **Never edit** `npins/sources.json` or `npins/default.nix` manually — always use `npins` CLI.
- **Check the [den changelog](https://den.oeiuwq.com/releases/)** before updating den — breaking changes in aspect syntax or schema are possible.
- **Never bump stateVersion** — it is set once at install time and must stay there. Bumping it does not upgrade existing state; it only changes defaults for newly created state and can silently break services. See [State Version](../../../docs/UPGRADE.md#state-version) in `docs/UPGRADE.md`.
- **Keep your LUKS passphrase** accessible — TPM unlock may break after firmware updates.

## References

- [`docs/UPGRADE.md`](../../../docs/UPGRADE.md) — full upgrade guide with cadence recommendations, **Pin Version Tracking** (per-pin snapshots and latest update investigations), rollback strategies, and post-update checklist
- [den changelog](https://den.oeiuwq.com/releases/)
- [npins](https://github.com/andir/npins)
