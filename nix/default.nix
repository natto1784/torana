{ ... }: {
  imports = [
    ./torana.nix
    ./torana-web.nix
  ];

  perSystem = { self', pkgs, ... }: {
    packages.default = self'.packages.torana;

    devShells.default = pkgs.mkShell {
      name = "torana-dev";
      inputsFrom = with self'.devShells; [
        torana
        torana-web
      ];
    };
  };
}
