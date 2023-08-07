{
  description = "torana danmaku";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/nixpkgs-unstable;

    crane = {
      url = github:ipetkov/crane;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = github:oxalica/rust-overlay;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    utils.url = github:numtide/flake-utils;
  };

  outputs = { self, nixpkgs, utils, crane, rust-overlay, }:
    utils.lib.eachDefaultSystem
      (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ rust-overlay.overlays.default ];
          };

          runtimeDependencies = with pkgs; [
            freetype
            fontconfig
            vulkan-loader
          ];

          xorgInputs = with pkgs; (with xorg; [
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

          toolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain;

          craneLib = (crane.mkLib pkgs).overrideToolchain toolchain;

          src = craneLib.cleanCargoSource (craneLib.path ./.);

          commonArgs = {
            inherit src nativeBuildInputs;
            buildInputs = xorgInputs;
            doCheck = false;
          };

          cargoArtifacts = craneLib.buildDepsOnly commonArgs;

          torana = craneLib.buildPackage (commonArgs // {
            inherit cargoArtifacts runtimeDependencies;
            nativeBuildInputs = nativeBuildInputs ++ [ pkgs.autoPatchelfHook ];
          });

          commonArgsWeb = {
            inherit src;
            cargoExtraArgs = "--target wasm32-unknown-unknown";
            doCheck = false;
          };

          cargoArtifactsWeb = craneLib.buildDepsOnly commonArgsWeb;

          toranaWeb = craneLib.buildPackage (commonArgsWeb // {
            inherit cargoArtifactsWeb;
          });

        in
        rec {
          packages = {
            inherit torana toranaWeb toolchain;
            default = torana;

            # not using flake checks to run them individually
            checks = {
              clippy = craneLib.cargoClippy (commonArgs // {
                inherit cargoArtifacts;
              });

              fmt = craneLib.cargoFmt {
                inherit src;
              };

              doc = craneLib.cargoDoc (commonArgs // {
                inherit cargoArtifacts;
              });

              nextest = craneLib.cargoNextest (commonArgs // {
                inherit cargoArtifacts;
                partitions = 1;
                partitionType = "count";
              });
            };

          };

          devShells = rec {
            torana = with pkgs;
              mkShell {
                name = "torana";
                nativeBuildInputs = nativeBuildInputs ++
                  (with pkgs; [ wasm-bindgen toolchain ]);

                LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath
                  (xorgInputs ++ runtimeDependencies);
              };

            default = torana;

            toranaWeb = with pkgs;
              mkShell {
                name = "toranaWeb";
                nativeBuildInputs = with pkgs; [
                  wasm-bindgen-cli
                ];
              };
          };
          formatter = pkgs.nixpkgs-fmt;
        }
      );
}
