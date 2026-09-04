# Mojo MAX SDK

This package provides Modular's official stable Mojo 1.0.0 SDK together with
the MAX runtime and accelerator libraries required for GPU programming.

It is intentionally separate from [`pkgs/mojo-source`](../mojo), which is the
AGPL-attributed overby source build. The source compiler currently exposes only
CPU/WebAssembly targets; adding MAX runtime files to it would not provide a
working GPU compiler.

## Contents

The package combines the coordinated Modular wheels for:

- Mojo 1.0.0 compiler and standard library
- Mojo LLDB/LSP tooling and formatter
- `max-core` 26.5.0
- MAX Mojo libraries
- `gpu-query`

The optional distributed GPU SHMEM and NIXL transport plugins are omitted.

The package is marked unfree because the official wheels contain native and
bytecode artifacts under Modular's MAX platform license. The source pin and
hashes are recorded in [`sources.json`](./sources.json).

This package is exposed as the default `pkgs.mojo` through the `local-pkgs`
overlay and installed system-wide by the `developer-tools` aspect. The source
build remains available as `pkgs.mojo-source`; it is not installed alongside
this package because both provide a `mojo` executable.

## GPU Validation

The Nix package adds `/run/opengl-driver/lib` to native binaries through
`autoAddDriverRunpath`. That allows the SDK to discover NixOS GPU drivers
without requiring `LD_LIBRARY_PATH`. The package intentionally does not bundle
CUDA or ROCm: those are host-provided accelerator drivers, and keeping them out
of the package allows the same SDK to work with NVIDIA or AMD systems.

On NixOS, the host GPU aspect should expose the matching user-space runtime
through `/run/opengl-driver/lib`. This lets the package's baked driver runpath
find HSA/HIP libraries without adding a hardware-specific dependency to the
package itself.

The upstream package validated CUDA on NVIDIA hardware. On this Framework
Desktop, validate AMD support manually after installation:

```bash
gpu-query
```

Then run the checked-in kernel-dispatch smoke test:

```bash
mojo pkgs/mojo-max/test_mojo_gpu.mojo
```

It creates a `DeviceContext`, compiles a kernel, launches two blocks of 64
threads, prints their IDs, and synchronizes before exiting. The current NixOS
configuration supplies ROCm libraries through the existing `modular-ai` aspect.

## Upgrade

1. Keep `version`, `maxVersion`, and all wheel versions synchronized.
2. Replace the URLs and SRI hashes in `sources.json` from the corresponding
   official Modular/PyPI release.
3. Ensure the `mojo`, `mojo-compiler`, `mojo-lldb-libs`, `max-core`, and MAX
   Mojo library versions are compatible.
4. Evaluate the configuration before downloading the wheels.
5. Verify `mojo --version`, `gpu-query`, and a GPU kernel after installation.

The stable release commit is `b4497b7ce9ba96331c72c637ad41b44bab374f33`, but
the wheel package is the appropriate artifact for that release; the compiler
source was not present in that commit.
