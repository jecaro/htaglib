{
  # inspired by: https://serokell.io/blog/practical-nix-flakes#packaging-existing-applications
  # description = "A Hello World in Haskell with a dependency and a devShell";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        overlays = [ self.overlay ];
      });
    in
    {
      overlay = (final: prev: {
        haskellPackages = prev.haskellPackages.override {
          overrides = hfinal: hprev: {
            htaglib = prev.haskell.lib.addExtraLibrary
              (hprev.callCabal2nix "htaglib" ./. { })
              final.taglib;
          };
        };
      });
      packages = forAllSystems (system: {
        htaglib = nixpkgsFor.${system}.haskellPackages.htaglib;
      });
      defaultPackage = forAllSystems (system: self.packages.${system}.htaglib);
      checks = self.packages;
      devShell = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          haskellPackages = pkgs.haskellPackages;
        in
        haskellPackages.shellFor {
          packages = p: [ self.packages.${system}.htaglib ];
          withHoogle = true;
          buildInputs =  [
            haskellPackages.cabal-install
            haskellPackages.ghcid
            haskellPackages.haskell-language-server
          ];
        });
    };
}
