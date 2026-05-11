{
  description = "PCO development environment";
  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";
  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSupportedSystem =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            pkgs = import nixpkgs { inherit system; };
          }
        );
    in
    {
      packages = forEachSupportedSystem (
        { pkgs }:
        let
          pco-synchro = pkgs.stdenv.mkDerivation {
            pname = "pco-synchro";
            version = "1.0";

            src = pkgs.fetchgit {
              url = "https://reds-gitlab.heig-vd.ch/reds-public/pco-synchro.git";
              rev = "HEAD";
              sha256 = "E6nRjyAfDlGO8VPf6UKGemt6BhaDjZF7l80flhxPZog=";
            };

            nativeBuildInputs = with pkgs; [
              cmake
              clang
              qt6.qtbase
            ];

            # CMAKE will automatically run from the sourceRoot directory
            cmakeFlags = [
              "-DCMAKE_BUILD_TYPE=Release"
            ];

            configurePhase = ''
              cd lib/pcosynchro
              cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$out
            '';

            buildPhase = ''
              cmake --build build
            '';

            installPhase = ''
              cd build
              make
              mkdir -p $out/lib $out/include
              make install
            '';

            dontWrapQtApps = true;
          };
        in
        {
          pco-synchro = pco-synchro;
          default = pco-synchro;
        }
      );

      devShells = forEachSupportedSystem (
        { pkgs }:
        let
          # Create custom Qt environment with required packages
          qtEnv =
            with pkgs.qt6;
            env "qt-dev-${qtbase.version}" [
              qtbase
              qtdeclarative
            ];
        in
        {
          default = pkgs.mkShell.override { } {
            packages = with pkgs; [
              clang-tools
              clang
              cmake
              gdb
              qtEnv
              qt6.qtbase
              qtcreator
              qt6.wrapQtAppsHook
              makeWrapper
              bashInteractive
              cppcheck
              doxygen
              gtest
              gbenchmark
              lcov
              (python3.withPackages (
                ps: with ps; [
                  pandas
                  matplotlib
                  markitdown
                ]
              ))
              self.packages.${pkgs.system}.pco-synchro
            ];
            shellHook = ''
              # Qt environment variables
              export QT_PLUGIN_PATH="${pkgs.qt6.qtbase}/lib/qt-6/plugins:$QT_PLUGIN_PATH"
              export NIXPKGS_QT6_QML_IMPORT_PATH="${pkgs.qt6.qtbase}/lib/qt-6/qml:$NIXPKGS_QT6_QML_IMPORT_PATH" 
              export QML2_IMPORT_PATH="$NIXPKGS_QT6_QML_IMPORT_PATH"

              export CMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH:${self.packages.${pkgs.system}.pco-synchro}
            '';
          };
        }
      );
    };
}
