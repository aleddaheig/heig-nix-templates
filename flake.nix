{
  # ============================================================
  # Script: data_processor.py
  # Original Author: @lucperkins
  # Source: https://github.com/the-nix-way/dev-templates
  # License: Mozilla Public License 2.0
  # Adapted by: Anthony Ledda, 2026
  # ============================================================
  description = "Ready-made templates for easily creating flake-driven environments";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";

  outputs =
    { self, ... }@inputs:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forEachSupportedSystem =
        f:
        inputs.nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            inherit system;
            pkgs = import inputs.nixpkgs { inherit system; };
          }
        );
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs, system }:
        {
          default =
            let
              getSystem = "SYSTEM=$(nix eval --impure --raw --expr 'builtins.currentSystem')";
              forEachDir = exec: ''
                for dir in */; do
                  (
                    cd "''${dir}"

                    ${exec}
                  )
                done
              '';

              script =
                name: runtimeInputs: text:
                pkgs.writeShellApplication {
                  inherit name runtimeInputs text;
                  bashOptions = [
                    "errexit"
                    "pipefail"
                  ];
                };
            in
            pkgs.mkShellNoCC {
              packages = with pkgs; [
                (script "build" [ ] ''
                  ${getSystem}

                  ${forEachDir ''
                    echo "building ''${dir}"
                    nix build ".#devShells.''${SYSTEM}.default"
                  ''}
                '')
                (script "check" [ nixfmt ] (forEachDir ''
                  echo "checking ''${dir}"
                  nix flake check --all-systems --no-build
                  nix develop --command which nixfmt
                ''))
                (script "format" [ nixfmt ] ''
                  git ls-files '*.nix' | xargs nix fmt
                '')
                (script "check-formatting" [ nixfmt ] ''
                  git ls-files '*.nix' | xargs nixfmt --check
                '')

                self.formatter.${system}
              ];
            };
        }
      );

      formatter = forEachSupportedSystem ({ pkgs, ... }: pkgs.nixfmt);

      packages = forEachSupportedSystem (
        { pkgs, system }:
        {
          default = self.packages.${system}.dvt;
          dvt = pkgs.writeShellApplication {
            name = "dvt";
            bashOptions = [
              "errexit"
              "pipefail"
            ];
            text = ''
              if [ -z "''${1}" ]; then
                echo "no template specified"
                exit 1
              fi

              TEMPLATE=$1

              nix \
                --experimental-features 'nix-command flakes' \
                flake init \
                --template \
                "https://flakehub.com/f/aleddaheig/heig-nix-templates/0.1#''${TEMPLATE}"
            '';
          };
        }
      );
    }

    //

      {
        templates = {
          default = self.templates.arn;

          arn = {
            path = ./arn;
            description = "ARN development environment";
          };

          asm = {
            path = ./asm;
            description = "ASM development environment";
          };

          cld = {
            path = ./cld;
            description = "CLD development environment";
          };

          cry = {
            path = ./cry;
            description = "CRY development environment";
          };

          daa = {
            path = ./daa;
            description = "DAA development environment";
          };

          dai = {
            path = ./dai;
            description = "DAI development environment";
          };

          isd = {
            path = ./isd;
            description = "ISD development environment";
          };

          isi = {
            path = ./isi;
            description = "ISI development environment";
          };

          pco = {
            path = ./pco;
            description = "PCO development environment";
          };

          pin = {
            path = ./pin;
            description = "PIN development environment";
          };

          poo = {
            path = ./poo;
            description = "POO development environment";
          };

          prg1 = {
            path = ./prg1;
            description = "PRG1 development environment";
          };

          prg2 = {
            path = ./prg2;
            description = "PRG2 development environment";
          };

          pst = {
            path = ./pst;
            description = "PST development environment";
          };

          slh = {
            path = ./slh;
            description = "SLH development environment";
          };

          sye = {
            path = ./sye;
            description = "SYE development environment";
          };

          web = {
            path = ./web;
            description = "WEB development environment";
          };
        };
      };
}
