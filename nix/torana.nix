{ ... }: {
  perSystem = { pkgs, src, craneLib, toolchain, ... }:
    let
      runtimeDependencies = with pkgs; [
        freetype
        fontconfig
        vulkan-loader
      ];

      buildInputs = with pkgs; (with xorg; [
        libX11
        libXcursor
        libXrandr
        libXi
      ]) ++ [
        # libxkbcommon
        # wayland
      ];

      nativeBuildInputs = with pkgs; [
        cmake
        openssl.dev
        fontconfig.dev
        pkg-config
      ]
      ++ lib.optionals (with stdenv.hostPlatform; (isx86 || isi686 || isAarch64)) [ mold ]
      ++ lib.optionals stdenv.hostPlatform.isDarwin [ darwin.apple_sdk.frameworks.Cocoa ];

      commonArgs = {
        inherit src nativeBuildInputs buildInputs;
        doCheck = false;
      };

      cargoArtifacts = craneLib.buildDepsOnly commonArgs;

      torana = craneLib.buildPackage (commonArgs // {
        inherit cargoArtifacts runtimeDependencies;
        nativeBuildInputs = nativeBuildInputs ++ [ pkgs.autoPatchelfHook ];
      });
    in
    {
      packages = {
        inherit torana;

        torana-clippy = craneLib.cargoClippy (commonArgs // {
          inherit cargoArtifacts;
        });

        torana-fmt = craneLib.cargoFmt {
          inherit src;
        };

        torana-doc = craneLib.cargoDoc (commonArgs // {
          inherit cargoArtifacts;
        });

        torana-nextest = craneLib.cargoNextest (commonArgs // {
          inherit cargoArtifacts;
          partitions = 1;
          partitionType = "count";
        });
      };

      devShells.torana = pkgs.mkShell {
        name = "torana";
        nativeBuildInputs = nativeBuildInputs
          ++ [ toolchain ];
        LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath
          (buildInputs ++ runtimeDependencies);
      };

    };
}
