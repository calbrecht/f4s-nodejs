{
  description = "nodejs tooling.";

  inputs = {
    pkgs-src = { url = github:calbrecht/f4s-nodejs?dir=pkgs; flake = false; };
  };

  outputs = { self, nixpkgs, pkgs-src }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ self.overlay ];
      };
      pkgs-dir = pkgs-src + /pkgs;
      node-packages = [
        "eslint"
        "eslint_d"
        "import-js"
        "jsonlint"
        "node-gyp"
        "node-gyp-build"
        "node-pre-gyp"
        "prettier"
        "standardx"
        "tslint"
        "typescript"
        "testcafe-browser-tools"
      ];
    in
    {
      apps."${system}".node2nixup = {
        type = "app";
        program = (pkgs.writeScriptBin "node2nix-update-node-packages.sh" ''
          set -e
          cd ./pkgs
          rm ./node-env.nix
          echo '${builtins.toJSON node-packages}' > node-packages.json
          ${pkgs.nodePackages.node2nix}/bin/node2nix \
            -i node-packages.json -o node-packages.nix -c composition.nix
        '') + /bin/node2nix-update-node-packages.sh;
      };

      legacyPackages."${system}" = {
        inherit (pkgs) nodejs nodejs_latest nodePackages nodePackages_latest;
      };

      overlay = final: prev: {
        #nodejs_legacy = prev.nodejs;
        #nodejs = prev.nodejs_latest;
        #
        nodePackages = prev.nodePackages //
          (prev.callPackage pkgs-dir { pkgs = final; });

        nodePackages_latest = prev.nodePackages_latest //
          (prev.callPackage pkgs-dir { pkgs = final; nodejs = final.nodejs_latest; }) // {
          # npm tries to fetch dev dependencies nowadays despite --production is given
          # https://github.com/npm/cli/issues/1969
          node2nix = (prev.nodePackages_latest.node2nix.override {
            dontNpmInstall = true;
            preRebuild = ''
              modules=$out/lib/node_modules
              mkdir -p $modules/.bin
              ln -s $modules/node2nix/bin/node2nix.js $modules/.bin/node2nix
            '';
          });
        };
      };
    };
}
