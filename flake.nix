{
  description = "nodejs tooling.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      top@{
        withSystem,
        lib,
        ...
      }:
      let
        x86_64 = "x86_64-linux";
        nodejsToolsHash = "sha256-1Ovf59U/JssT67i0wprFXAU236juMyFbqvG+Fl141fM=";
      in
      {
        systems = [ x86_64 ];
        flake = withSystem x86_64 (
          { ... }:
          {
            overlays = {
              default = (
                final: prev: {
                  pnpm = prev.pnpm_10.override { nodejs = prev.nodejs_latest; };

                  nodejs-tools = prev.stdenv.mkDerivation (finalAttrs: {
                    pname = "nodejs-tools";
                    version = "latest";

                    src = ./.;

                    nativeBuildInputs = [
                      prev.nodejs_latest
                      prev.pnpmConfigHook
                      final.pnpm
                    ];

                    pnpmDeps = prev.fetchPnpmDeps {
                      inherit (finalAttrs) pname version src;
                      pnpm = final.pnpm;
                      fetcherVersion = 3;
                      hash = nodejsToolsHash;
                    };

                    installPhase = ''
                      mkdir -p $out
                      cp -r ./node_modules/.pnpm $out/.pnpm
                      cp -r ./node_modules/.bin $out/bin
                    '';
                  });
                }
              );
              #eslint_d = (_nodePackages.eslint_d.override {
              #  dontNpmInstall = true;
              #  preRebuild = ''
              #    substituteInPlace bin/eslint_d.js --replace "'../lib/options'" "'../lib/options-cliengine'"
              #  modules=$out/lib/node_modules
              #  mkdir -p $modules/.bin
              #  ln -s $modules/eslint_d/bin/eslint_d.js $modules/.bin/eslint_d
              #  ln -s $modules/eslint_d/bin/eslint.js $modules/.bin/eslint
              #  '';
              #});
            };
          }
        );
        perSystem =
          {
            system,
            pkgs,
            ...
          }:
          {
            _module.args.pkgs = import inputs.nixpkgs {
              inherit system;
              config = {
                allowUnfree = true;
              };
              overlays = [
                top.config.flake.overlays.default
              ];
            };

            legacyPackages = {
              inherit (pkgs)
                nodejs
                nodejs_latest
                pnpm
                nodejs-tools
                ;
            };

            formatter =
              (inputs.treefmt-nix.lib.evalModule pkgs {
                programs.nixfmt.enable = true;
              }).config.build.wrapper;
          };
      }
    );
}
