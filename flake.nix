{
  description = "Zenn CLI environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:

      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) importNpmLock;
        nodejs = pkgs.nodejs_24;
        npmRoot = ./node-pkgs;

      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            importNpmLock.hooks.linkNodeModulesHook
            pkgs.nodejs
            pkgs.just
            pkgs.treefmt
            pkgs.lychee
            pkgs.gitleaks
          ];

          npmDeps = importNpmLock.buildNodeModules {
            inherit npmRoot nodejs;
          };

          # https://nixos.org/manual/nixpkgs/stable/#javascript-packages-nixpkgs
          postShellHook = ''
            git config core.hooksPath .githooks
          '';
        };

        # for updating package.json and package-lock.json
        devShells.node = pkgs.mkShell {
          packages = [
            nodejs
            pkgs.npm-check-updates
          ];
        };

        formatter = pkgs.writeShellApplication {
          name = "treefmt";
          runtimeInputs = [ pkgs.treefmt ];
          text = ''
            treefmt --config-file ./.config/treefmt.toml
          '';
        };
      }
    );
}
