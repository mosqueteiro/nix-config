# Mojo

This directory contains a Nix package for the Mojo compiler and developer
tools, built from the open-source Modular repository with Bazel.

The package is based on Niclas Overby's source-build implementation:

<https://github.com/overby-me/overby-me/tree/main/platform/nix/packages/mojo>

The copied and modified recipe files are covered by the GNU Affero General
Public License, version 3 only. See [`NOTICE`](./NOTICE) and [`LICENSE`](./LICENSE).

## Source Pin

The package currently uses:

- Modular commit: `f66d4d522c34be0a961ffac3dbfc81e30f67942e`
- Mojo version: `1.1.0-dev2026081813`
- Local source reference: `overby-pinned` at the same commit in `~/Projects/modular/modular`

The official `mojo/v1.0.0` commit, `b4497b7ce9ba96331c72c637ad41b44bab374f33`,
predates the compiler source release. It contains the stable wheel metadata but
does not contain the `//KGEN:mojo` source target required by this package.

## Build Design

The derivation is intentionally split into three stages:

1. `deps` is a fixed-output derivation that downloads Bazel repositories and
   preserves the module lockfile and repository cache.
2. `build` performs the multi-hour LLVM and Mojo compilation and exports raw
   compiler artifacts. It is exposed through `pkgs.mojo.build` for inspection.
3. The final `mojo` derivation performs packaging, ELF fixing, wrappers,
   configuration, and smoke tests.

Changes to the source revision, `nix-build.patch`, Bazel flags, or Bazel target
lists invalidate the expensive `build` stage. Changes limited to final package
layout or wrappers can reuse it.

Build the configured system with:

```bash
nixos-rebuild build --file . -A nixosConfigurations.frameworkDesktop
```

The package is exposed through the `local-pkgs` overlay and installed in the
`mosqueteiro` home-manager profile.

## `nix-build.patch`

This is a unified diff applied to the fetched Modular source by the Nix
`patches` attribute. It does not modify this package's `default.nix`.

It makes two changes:

- Adds the WebAssembly LLVM backend to Modular's selected backend list.
- Teaches the host target matcher to accept WebAssembly triples.

The FHS and Nix sandbox workarounds are implemented in `default.nix`, mainly in
`bazelEnv`, `prepareExternal`, and the two Bazel build phases.

## Current Scope

The package provides the source-built Mojo compiler, standard library, LLVM
tools, LSP server, LLDB integration, REPL entry point, formatter, and Jupyter
kernel files.

This source build does not provide the full MAX/GPU SDK. In particular, it does
not package `max-core`, MAX Mojo libraries, or GPU target implementations. Use
the existing Pixi-based Modular tooling for MAX/GPU work until a separate
version-matched binary SDK package is added.

## Upgrade

1. Select a Modular commit after the compiler source was open-sourced.
2. Update `version`, `rev`, and the `fetchFromGitHub` hash in `default.nix`.
3. Check that the commit's `bazel` layout still matches `nix-build.patch`.
4. Refresh the fixed-output `deps.outputHash` when the Bazel repository graph
   changes. Nix reports the required hash for a mismatch.
5. Run the full build and verify `mojo --version`, interpreted execution, and
   compiled execution.

Do not use the stable `b4497b7ce9ba96331c72c637ad41b44bab374f33` release commit
for this source package. Use the corresponding prebuilt stable wheels instead
if stable 1.0.0 is required.
