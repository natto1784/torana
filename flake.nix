{
  description = "Torana danmaku engine";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/release-22.11;
    rust-overlay.url = github:oxalica/rust-overlay;
    utils.url = github:numtide/flake-utils;
  };

  outputs = {
    self,
    nixpkgs,
    utils,
    rust-overlay,
  }:
    utils.lib.eachDefaultSystem
    (
      system: let
        overlays = [rust-overlay.overlays.default];

        pkgs = import nixpkgs {
          inherit system overlays;
        };

        toolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain;
      in rec {
        devShell = with pkgs;
          mkShell {
            nativeBuildInputs =
              [
                cmake
                openssl
                fontconfig
                pkg-config
                rust-analyzer
                toolchain
              ]
              ++ lib.optionals (with stdenv.hostPlatform; (isx86 || isi686 || isAarch64) && isLinux) [llvmPackages.lld]
              ++ lib.optionals stdenv.hostPlatform.isDarwin [darwin.apple_sdk.frameworks.Cocoa];
          };

        formatter = pkgs.alejandra;
      }
    );
}
