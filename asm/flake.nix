{
  description = "ASM development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Cross-toolchain for bare i686
        pkgsCross-i686 = import nixpkgs {
          localSystem = system;
          crossSystem = {
            config = "i686-unknown-linux-gnu";
          };
        };

        # Cross-toolchain for ARMv7 hard-float
        pkgsCross-armv7 = import nixpkgs {
          localSystem = system;
          crossSystem = nixpkgs.lib.systems.examples.armv7l-hf-multiplatform;
        };

        armToolchain = pkgs.runCommand "arm-linux-gnueabihf-toolchain" { } ''
          mkdir -p $out/bin
          for bin in ${pkgsCross-armv7.stdenv.cc}/bin/armv7l-unknown-linux-gnueabihf-*; do
            name=$(basename $bin)
            short=''${name/armv7l-unknown-linux-gnueabihf-/arm-linux-gnueabihf-}
            ln -s $bin $out/bin/$short
          done

          # Add arm-linux-gnueabihf-gdb
          ln -s ${pkgsCross-armv7.buildPackages.gdb}/bin/armv7l-unknown-linux-gnueabihf-gdb \
                $out/bin/arm-linux-gnueabihf-gdb
        '';

        i686Toolchain = pkgs.runCommand "i686-linux-toolchain" { } ''
          mkdir -p $out/bin
          for bin in ${pkgsCross-i686.stdenv.cc}/bin/i686-unknown-linux-gnu-*; do
            name=$(basename $bin)
            short=''${name/i686-unknown-linux-gnu-/i686-linux-}
            ln -s $bin $out/bin/$short
          done
        '';

      in
      {
        devShells.default = pkgs.mkShell {
          name = "cross-env";

          # Native build tools (run on host)
          nativeBuildInputs = with pkgs; [
            # QEMU system emulators
            qemu
            # Toolchain helpers
            pkg-config
            # Packages
            bashInteractive
            eclipses.eclipse-embedcpp
            bear
            gcc_multi
          ];

          # Cross-compilers for i686
          # Use $i686_CC, $i686_AR etc. via wrapper scripts, or set them manually
          buildInputs = [
            armToolchain
            i686Toolchain
            pkgsCross-i686.stdenv.cc # i686 GCC toolchain
            pkgsCross-armv7.stdenv.cc # ARMv7 GCC toolchain
            pkgs.glibc_multi
          ];

          env = {
            QEMU_DATA_DIR = "${pkgs.qemu}/share/qemu";
            QEMU_ROMS = "${pkgs.qemu}/share/qemu";
          };

          shellHook = ''
            export LD_LIBRARY_PATH="${pkgs.ncurses}/lib:$LD_LIBRARY_PATH"
          '';
        };
      }
    );
}
