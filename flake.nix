{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    with flake-utils.lib;
    with nixpkgs.lib;
    eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        bundlers = rec {
          toRelocatable = (pkgs.callPackage ./default.nix { });
          default = toRelocatable;
        };
      });
}
