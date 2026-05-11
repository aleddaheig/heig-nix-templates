{
  description = "CRY development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        python = pkgs.python312;
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            uv
            openssl
            openssl.dev
            pkg-config
            (sage.override {
              extraPythonPackages =
                ps: with ps; [
                  pycryptodome
                ];
            })
            bashInteractive
          ];

          shellHook = ''
            export PKG_CONFIG_PATH="${pkgs.openssl.dev}/lib/pkgconfig"
            export OPENSSL_DIR="${pkgs.openssl.dev}"
            export OPENSSL_LIB_DIR="${pkgs.openssl.out}/lib"
            export UV_PYTHON=${python}
            export UV_PYTHON_PREFERENCE="only-system"

            if [ ! -d ".venv" ]; then
              uv venv .venv
            fi
            source .venv/bin/activate
          '';
        };
      }
    );
}
