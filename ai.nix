{ pkgs, ... }:
{    
  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      llama-cpp =
        (pkgs.llama-cpp.override {
          cudaSupport = false;
          rocmSupport = true;
          metalSupport = false;
          blasSupport = true;
        }).overrideAttrs
          (oldAttrs: rec {
            version = "7951";
            src = pkgs.fetchFromGitHub {
              owner = "ggml-org";
              repo = "llama.cpp";
              tag = "b${version}";
              hash = "sha256-XIaCw5GLR0mov7X1OTuu7Zpvi7s0SGNKt8zroBoZG7I=";
              leaveDotGit = true;
              postFetch = ''
                git -C "$out" rev-parse --short HEAD > $out/COMMIT
                find "$out" -name .git -print0 | xargs -0 rm -rf
              '';
            };
            CXX = "${pkgs.rocmPackages.llvm.clang}/bin/hipcc";
            CC = "${pkgs.rocmPackages.llvm.clang}/bin/hipcc";
            cmakeFlags = (oldAttrs.cmakeFlags or []) ++ [
              "-DGGML_NATIVE=ON"
              "-DGGML_HIPBLAS=ON"
              "-DLLAMA_CURL=ON"
              "-DAMDGPU_TARGETS=gfx1100"
              "-DGPU_TARGETS=gfx1100"
            ];
            env.AMDGPU_TARGETS = "gfx1100"; #shall be 1103 ideally
            env.HIP_PLATFORM = "amd";

            # Disable Nix's NIX_ENFORCE_NO_NATIVE which strips -march=native flags
            # See: https://github.com/NixOS/nixpkgs/issues/357736
            # See: https://github.com/NixOS/nixpkgs/pull/377484 (intentionally contradicts this)
            preConfigure = ''
              export NIX_ENFORCE_NO_NATIVE=0
              ${oldAttrs.preConfigure or ""}
            '';
          });

      # llama-swap from GitHub releases
      llama-swap = pkgs.runCommand "llama-swap" { } ''
        mkdir -p $out/bin
        tar -xzf ${
          pkgs.fetchurl {
            url = "https://github.com/mostlygeek/llama-swap/releases/download/v175/llama-swap_175_linux_amd64.tar.gz";
            hash = "sha256-zeyVz0ldMxV4HKK+u5TtAozfRI6IJmeBo92IJTgkGrQ=";
          }
        } -C $out/bin
        chmod +x $out/bin/llama-swap
      '';
    };
  };
  environment.systemPackages = with pkgs; [
    llama-cpp
  ];
}
