{
  description = "DAA development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        config.android_sdk.accept_license = true;
      };

      javaVersion = 21;
      system = "x86_64-linux";
    in
    {
      overlays.default =
        final: prev:
        let
          jdk = prev."jdk${toString javaVersion}";
        in
        {
          maven = prev.maven.override { jdk_headless = jdk; };
          gradle = prev.gradle.override { java = jdk; };
          kotlin = prev.kotlin.override { jre = jdk; };
        };

      devShells.${system}.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          gradle
          kotlin
        ];

        buildInputs = with pkgs; [
          bashInteractive
        ];

        shellHook = ''
          export JAVA_HOME=${pkgs.jdk.home}
          export PATH=$PATH:$HOME/.pub-cache/bin

          echo "Java: $JAVA_HOME"
        '';

      };
    };
}
