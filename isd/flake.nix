{
  description = "A Nix-flake-based Python development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";

  outputs =
    { self, ... }@inputs:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSupportedSystem =
        f:
        inputs.nixpkgs.lib.genAttrs supportedSystems (
          system: f { pkgs = import inputs.nixpkgs { inherit system; }; }
        );

      version = "3.13";
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs }:
        let
          concatMajorMinor =
            v:
            pkgs.lib.pipe v [
              pkgs.lib.versions.splitVersion
              (pkgs.lib.sublist 0 2)
              pkgs.lib.concatStrings
            ];

          python = pkgs."python${concatMajorMinor version}";

          pythonGapminder = python.pkgs.buildPythonPackage rec {
            pname = "gapminder";
            version = "0.1";
            format = "setuptools";

            src = python.pkgs.fetchPypi {
              inherit pname version;
              sha256 = "sha256-SLFMCISrXRWFoU5iI/qZphHALHbvLyz7mVnhTeGc+Vw=";
            };

            propagatedBuildInputs = with python.pkgs; [ pandas ];

            doCheck = false;
          };
        in
        {
          default = pkgs.mkShellNoCC {
            venvDir = ".venv";

            postShellHook = ''
              venvVersionWarn() {
                local venvVersion
                venvVersion="$("$venvDir/bin/python" -c 'import platform; print(platform.python_version())')"
                [[ "$venvVersion" == "${python.version}" ]] && return
                cat <<EOF
              Warning: Python version mismatch: [$venvVersion (venv)] != [${python.version}]
                       Delete '$venvDir' and reload to rebuild for version ${python.version}
              EOF
              }
              venvVersionWarn
            '';

            buildInputs = [ pkgs.bashInteractive ];

            packages = with python.pkgs; [
              venvShellHook
              pip
              jupyter
              notebook
              ipykernel
              pythonGapminder
              matplotlib
              plotly
              pandas
              scikit-learn
              seaborn
              numpy
            ];
          };
        }
      );
    };
}
