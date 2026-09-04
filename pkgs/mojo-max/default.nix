{
  autoAddDriverRunpath,
  autoPatchelfHook,
  fetchurl,
  lib,
  libbsd,
  libtinfo,
  makeWrapper,
  python3,
  runCommand,
  stdenv,
  unzip,
}:

let
  release = builtins.fromJSON (builtins.readFile ./sources.json);
  systemSources = release.systems.${stdenv.hostPlatform.system};
  fetchWheel = source: fetchurl { inherit (source) url hash; };
  pythonDependencies = with python3.pkgs; [
    click
    mypy-extensions
    pathspec
    platformdirs
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "mojo";
  inherit (release) version;

  strictDeps = true;
  __structuredAttrs = true;

  # The official SDK is distributed as several coordinated wheels. MAX's core
  # runtime and Mojo libraries are required for accelerator compilation. Do not
  # add CUDA or ROCm here: the host supplies the selected accelerator driver.
  srcs = map fetchWheel [
    systemSources.mojo
    systemSources.mojoCompiler
    systemSources.mojoLldbLibs
    systemSources.maxCore
    release.common.mojoCompilerMojoLibs
    release.common.maxMojoLibs
    release.common.mblack
  ];

  nativeBuildInputs = [
    autoPatchelfHook
    autoAddDriverRunpath
    makeWrapper
    unzip
  ];

  buildInputs = [
    libbsd
    # Upstream LLDB links against the non-wide ncurses/terminfo ABI.
    libtinfo
    stdenv.cc.cc.lib
  ];

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    runHook preUnpack

    mkdir wheels
    wheelNumber=0
    for wheel in "''${srcs[@]}"; do
      wheelNumber=$((wheelNumber + 1))
      mkdir "wheels/$wheelNumber"
      unzip -q "$wheel" -d "wheels/$wheelNumber"
    done

    runHook postUnpack
  '';

  installPhase = ''
        runHook preInstall

        sitePackages=$out/${python3.sitePackages}
        mkdir -p "$sitePackages" "$out/bin"

        for wheel in wheels/*; do
          for platlib in "$wheel"/*.data/platlib; do
            if [ -d "$platlib" ]; then
              cp -a "$platlib"/. "$sitePackages"/
            fi
          done

          for entry in "$wheel"/*; do
            case "$entry" in
              *.data) ;;
              *) cp -a "$entry" "$sitePackages"/ ;;
            esac
          done
        done

        # NIXL transport plugins are optional and require additional distributed
        # communication stacks. Keep the core library used by libmax.
        rm -rf "$sitePackages/modular/lib/nixl"

        writeEntryPoint() {
          local program=$1
          local module=$2
          local function=$3

          cat > "$out/bin/$program" <<EOF
    #!${python3.interpreter}
    import sys
    sys.path[:0] = ["$sitePackages"] + "${python3.pkgs.makePythonPath pythonDependencies}".split(":")
    from $module import $function
    $function()
    EOF
          chmod +x "$out/bin/$program"
        }

        writeEntryPoint mojo mojo._entrypoints exec_mojo
        writeEntryPoint lld mojo._entrypoints exec_lld
        writeEntryPoint modular-crashpad-handler mojo._entrypoints exec_modular_crashpad_handler
        writeEntryPoint gpu-query _mojo._entrypoints exec_gpu_query
        writeEntryPoint lldb-argdumper _mojo._entrypoints exec_lldb_argdumper
        writeEntryPoint lldb-server _mojo._entrypoints exec_lldb_server
        writeEntryPoint llvm-symbolizer _mojo._entrypoints exec_llvm_symbolizer
        writeEntryPoint mojo-lldb _mojo._entrypoints exec_mojo_lldb
        writeEntryPoint mojo-lsp-server _mojo._entrypoints exec_mojo_lsp_server
        writeEntryPoint mblack mblack patched_main

        # lldb-dap supplies its plugin and visualizer paths through the process
        # environment rather than the generic entry-point helper.
        cat > "$out/bin/lldb-dap" <<EOF
    #!${python3.interpreter}
    import os
    import sys
    sys.path[:0] = ["$sitePackages"] + "${python3.pkgs.makePythonPath pythonDependencies}".split(":")
    os.environ.setdefault("MODULAR_MOJO_MAX_LLDB_PLUGIN_PATH", "$sitePackages/modular/lib/libMojoLLDB.so")
    os.environ.setdefault("MODULAR_MOJO_MAX_LLDB_VISUALIZERS_PATH", "$sitePackages/modular/lib/lldb-visualizers")
    from _mojo._entrypoints import exec_lldb_dap
    exec_lldb_dap()
    EOF
        chmod +x "$out/bin/lldb-dap"

        runHook postInstall
  '';

  postFixup = ''
    for program in \
      gpu-query \
      lld \
      lldb-argdumper \
      lldb-dap \
      lldb-server \
      llvm-symbolizer \
      modular-crashpad-handler \
      mojo-lldb \
      mojo-lsp-server
    do
      wrapProgram "$out/bin/$program" --prefix PATH : "$out/bin"
    done

    wrapProgram "$out/bin/mojo" \
      --prefix PATH : "$out/bin:${lib.makeBinPath [ stdenv.cc ]}"
  '';

  passthru.tests = {
    hello = runCommand "mojo-max-hello" { nativeBuildInputs = [ finalAttrs.finalPackage ]; } ''
      export HOME="$TMPDIR"
      mojo --version
      printf '%s\n' 'def main():' '    print("Hello from Mojo")' > hello.mojo
      mojo hello.mojo | grep -F "Hello from Mojo"
      touch "$out"
    '';

    # PTX generation does not require a GPU and verifies that the packaged
    # compiler and MAX libraries support accelerator compilation.
    cuda-codegen =
      runCommand "mojo-max-cuda-codegen"
        {
          nativeBuildInputs = [ finalAttrs.finalPackage ];
        }
        ''
          export HOME="$TMPDIR"
          cat > cuda-kernel.mojo <<'EOF'
          from max.gpu.host import DeviceContext
          from std.gpu import thread_idx

          def kernel():
              print(thread_idx.x)

          def main() raises:
              with DeviceContext() as ctx:
                  ctx.enqueue_function[kernel](grid_dim=1, block_dim=1)
          EOF

          mojo build cuda-kernel.mojo \
            --target-accelerator sm_75 \
            --emit asm \
            -o cuda-kernel.s
          ptx=$(find . -maxdepth 1 -name 'cuda-kernel_*.ptx' -print -quit)
          test -n "$ptx"
          grep -Fx '.target sm_75' "$ptx"
          grep -F '.visible .entry' "$ptx"
          grep -F '%tid.x' "$ptx"
          touch "$out"
        '';
  };

  meta = {
    description = "Official Mojo 1.0 SDK with MAX accelerator support";
    longDescription = ''
      The official stable Mojo 1.0.0 toolchain and the MAX runtime libraries
      required for GPU programming. Optional distributed GPU SHMEM and NIXL
      transport plugins are intentionally omitted.
    '';
    homepage = "https://www.modular.com/mojo";
    license = lib.licenses.unfree;
    platforms = [
      "aarch64-linux"
      "x86_64-linux"
    ];
    sourceProvenance = with lib.sourceTypes; [
      binaryBytecode
      binaryNativeCode
    ];
    mainProgram = "mojo";
  };
})
