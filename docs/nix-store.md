# Nix Store

## `/nix/store` paths

A Nix store path is an immutable directory under `/nix/store`. Most derivation outputs are input-addressed: their paths are derived from the build recipe and its inputs. Fixed-output derivations and content-addressed paths are special cases whose identity is tied to an expected or computed content hash. Packages, configuration files, and build artifacts created by Nix live here as distinct, isolated paths.

---

### Anatomy of a Store Path

A standard store path looks like this:

```text
/nix/store/c730kcf3h7ch0asdrfba46mkwxwr3b9p-openssl-3.0.12
\________/ \______________________________/ \____________/
  Root                  Hash                   Human Name

```

1. **Root Directory:** `/nix/store/` (the default store root on NixOS).
2. **The 32-Character Hash:** A Base-32 string using Nix's custom alphabet `0123456789abcdfghijklmnpqrsvwxyz`. It omits `e`, `o`, `u`, and `t` to avoid accidental words.
3. **Human Name:** A human-readable identifier appended to the hash for usability, usually ending in the package version or file type (e.g., `-source`, `-etc`, `-drv`).

---

### How the Hash is Generated

The hash is what gives Nix its determinism. The exact path-addressing mode depends on how the derivation is built:

* **Input-Addressed (Default):** The path is derived from the derivation and its inputs. This includes the builder, arguments, environment, source, and referenced dependency paths. Changing any of those inputs produces a different store path.
* **Fixed-Output / Content-Verified:** Fetched sources such as `fetchgit` declare an expected hash for the resulting output. Nix verifies that the downloaded source matches it; changing the resulting content requires a different hash.

Content-addressed derivations are another store-path mode where the output content determines the path. They are distinct from the usual input-addressed derivation outputs.

---

### Key Properties of Store Paths

* **Immutability:** Once written to `/nix/store`, paths are read-only. Nix commonly normalizes timestamps to Unix time `1` (`1970-01-01 00:00:01`), helping prevent build timestamps from introducing unnecessary differences.
* **Explicit Runtime Dependencies:** Dynamically linked Nix-built binaries typically use RPATHs pointing directly to the required `/nix/store/<hash>-dependency` paths instead of searching conventional system library directories.
* **Coexistence of Versions:** Multiple versions (or even different builds of the *same* version with different compiler flags) live side-by-side without interference.

---

### Profiles and `/run/current-system`

Profiles and NixOS generations are mostly symlinks to store paths rather than copies of their contents. The active NixOS system is exposed through:

```text
/run/current-system -> /nix/store/<hash>-nixos-system-<host>
```

This is why commands and applications from the active system can resolve to paths under `/nix/store`. To inspect the active system path:

```bash
readlink -f /run/current-system
```

User profiles such as `~/.nix-profile` work similarly.

---

### Common Suffix Conventions

When looking through `/nix/store`, you will see common suffix patterns that hint at what generated the path:

| Suffix Pattern | Content / Description |
| --- | --- |
| **`-source`** | A raw source tree downloaded from Git, Tarball, or local directory. |
| **`-nixpkgs`** | A copy of the Nixpkgs expression tree. |
| **`.drv`** | A **derivation file**—the uncompiled build recipe (containing build steps, environment variables, and dependencies). |
| **`-etc` / `-systemd**` | Generated NixOS configuration files and systemd service units. |
| **`-bin` / `-dev` / `-lib`** | Common split outputs containing executables, headers, or dynamic libraries. |

---

### Useful Commands for Navigating Store Paths

```bash
# Replace this example with a real path from /nix/store.

# Find direct referrers to a path (what refers to it)
nix-store --query --referrers /nix/store/c730kcf3...-openssl-3.0.12

# View the full dependency tree of a store path
nix-store --query --tree /nix/store/c730kcf3...-openssl-3.0.12

# Calculate the total closure size of a path, including dependencies.
# This is not necessarily additional disk usage because paths can be shared.
nix path-info -Sh /nix/store/c730kcf3...-openssl-3.0.12

```
