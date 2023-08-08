{ ... }: {
  perSystem = { pkgs, src, craneLib, toolchain, ... }:
    let
      commonArgs = {
        inherit src;
        cargoExtraArgs = "--target wasm32-unknown-unknown";
        doCheck = false;
      };

      cargoArtifacts = craneLib.buildDepsOnly commonArgs;

      torana = craneLib.buildPackage (commonArgs // {
        inherit cargoArtifacts;
      });
    in
    {
      packages = {
        torana-web = torana;

        torana-web-clippy = craneLib.cargoClippy (commonArgs // {
          inherit cargoArtifacts;
        });

        torana-web-fmt = craneLib.cargoFmt {
          inherit src;
        };

        torana-web-doc = craneLib.cargoDoc (commonArgs // {
          inherit cargoArtifacts;
        });

        torana-web-nextest = craneLib.cargoNextest (commonArgs // {
          inherit cargoArtifacts;
          partitions = 1;
          partitionType = "count";
        });
      };

      devShells.torana-web = pkgs.mkShell {
        name = "torana-web";
        nativeBuildInputs = [
          pkgs.wasm-bindgen-cli
          toolchain
        ];
      };

    };
}
