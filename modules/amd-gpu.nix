{ den, ... }: {
  den.aspects.amd-gpu = {
    nixos = { pkgs, ... }: {
      # ROCm & Graphics Support
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          # Expose the HSA runtime through /run/opengl-driver/lib for
          # Nix-linked GPU consumers such as the global Mojo SDK.
          rocmPackages.rocm-runtime
          rocmPackages.clr
          rocmPackages.clr.icd # Enables HIP/ROCm
        ];
      };
      hardware.amdgpu.opencl.enable = true;

      environment.systemPackages = with pkgs; [
        rocmPackages.rocminfo
        rocmPackages.rocm-smi
      ];

    };
  };

  den.aspects.strix-halo-gpu = {
    includes = [
      den.aspects.amd-gpu
    ];
    nixos = { ... }: {
      environment.variables = {
        # Required overrides for Strix Point/Halo (gfx1151)
        HSA_OVERRIDE_GFX_VERSION = "11.5.1";
        HCC_AMDGPU_TARGET = "gfx1151";
      };
    };

    homeManager =
      { ... }:
      {
        home.sessionVariables = {
          # Required overrides for Strix Point/Halo (gfx1151)
          HSA_OVERRIDE_GFX_VERSION = "11.5.1";
          HCC_AMDGPU_TARGET = "gfx1151";
        };
      };
  };

}
