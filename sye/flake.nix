{
  description = "SYE development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          let
            pkgs = import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
            # 32‑bit packages for x86_64 via pkgsi686Linux (headers/libs, not executables)
            pkgs32 = pkgs.pkgsi686Linux;
            lib = pkgs.lib;
            fixShebangs = pkgs.writeShellScriptBin "fixShebangs" ''
              #!/usr/bin/env bash

              # Fonction pour fixer les shebangs récursivement
              fix_shebangs() {
                local target_dir="''${1:-.}"
                echo "Fixing shebangs in: $target_dir"
                
                find "$target_dir" -name "*.sh" -type f -executable \
                  -exec sed -i 's|#!/bin/bash|#!/usr/bin/env bash|g' {} \;
                
                find "$target_dir" -name "*.sh" -type f -executable \
                  -exec sed -i 's|#!/bin/sh|#!/usr/bin/env sh|g' {} \;
                  
                echo "Shebangs fixed!"
              }

              fix_shebangs "$@"
            '';

          in
          f pkgs pkgs32 lib fixShebangs
        );
    in
    {
      devShells = forAllSystems (
        pkgs: pkgs32: lib: fixShebangs: {
          default = pkgs.mkShell {
            packages =
              with pkgs;
              [
                clang-tools
                clang
                bashInteractive
                fixShebangs

                # --- Core build / toolchain ("build-essential") ---
                gcc_multi # 32‑/64‑bit libstdc++/libgcc
                gnumake
                cmake
                pkg-config
                binutils

                # --- Compression / utils ---
                unzip
                bc
                elfutils
                ubootTools # u-boot-tools
                dtc # device-tree-compiler
                util-linux # provides fdisk, etc.
                mtools
                wget

                # --- Networking ---
                dnsmasq
                nettools
                bridge-utils

                # --- GUI libs (for GTK2 builds that some SDKs still want) ---
                gtk2

                # --- Emulators / debug ---
                qemu_full # supersedes qemu-system & qemu-system-arm
                gdb

                # --- Curses headers (both v6 and v5 compat if available) ---
                ncurses
              ]
              # 32‑bit development libraries rough equivalents of :i386 packages
              ++ [
                pkgs32.zlib # zlib1g:i386 / lib32z1-dev
                pkgs32.ncurses
              ]
              # Some channels still have ncurses5; include 64‑bit and 32‑bit if available
              ++ lib.optionals (pkgs ? ncurses5) [ pkgs.ncurses5 ]
              ++ lib.optionals (pkgs32 ? ncurses5) [ pkgs32.ncurses5 ]
              # ARM bare‑metal toolchain (gcc-arm-none-eabi)
              ++ (with pkgs; [
                gcc-arm-embedded
              ]);

            # Environment tweaks helpful for multi‑arch builds
            shellHook = ''
              echo "Usage: fixShebangs [directory]"
              echo
              echo "→ Dev shell ready." \
              "gcc_multi=$(gcc -v 2>&1 | tail -n1)" \
              "pkgs=${pkgs.system}"
              echo "→ 32-bit libs available via pkgsi686Linux for zlib/ncurses (no 32‑bit binaries)."
              echo
            '';
          };
        }
      );
    };
}
