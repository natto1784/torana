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

    flake-parts.url = github:hercules-ci/flake-parts;
  };

  outputs = inputs@{ self, nixpkgs, crane, rust-overlay, flake-parts }:
    flake-parts.lib.mkFlake { inherit inputs; } {

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "i686-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      imports = [
        ./nix
      ];

      perSystem = { self', system, ... }:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ rust-overlay.overlays.default ];
          };

          toolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain;
          craneLib = (crane.mkLib pkgs).overrideToolchain toolchain;

          filterWgsl = path: _: builtins.match ".*\.wgsl$" path != null;
          filterSrc = path: type:
            (filterWgsl path type) || (craneLib.filterCargoSources path type);

          src = pkgs.lib.cleanSourceWith {
            src = craneLib.path ./.;
            filter = filterSrc;
          };
        in
        rec {
          _module.args = {
            inherit src craneLib toolchain pkgs;
          };

          formatter = pkgs.nixpkgs-fmt;
        };
    };
}
