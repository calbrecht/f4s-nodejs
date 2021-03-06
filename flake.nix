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
        #"jison" # devDependency of jsonlint
        "jsonlint"
        "node-gyp"
        "node-gyp-build"
        "node-pre-gyp"
        "prettier"
        "standardx"
        "tslint"
        "typescript"
        "testcafe-browser-tools"
        "trepan-ni"
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

      defaultPackage."${system}" = self.legacyPackages."${system}".nodejs;

      overlay = final: prev:
        let
          _nodePackages = (prev.callPackage pkgs-dir { pkgs = final; });
          _nodePackages_latest = (prev.callPackage pkgs-dir { pkgs = final; nodejs = final.nodejs_latest; });
        in
        {
          #nodejs_legacy = prev.nodejs;
          #nodejs = prev.nodejs_latest;
          #
          nodePackages = prev.nodePackages // _nodePackages // {
            eslint_d = (_nodePackages.eslint_d.override {
              dontNpmInstall = true;
              preRebuild = ''
                substituteInPlace bin/eslint_d.js --replace "'../lib/options'" "'../lib/options-cliengine'"
                modules=$out/lib/node_modules
                mkdir -p $modules/.bin
                ln -s $modules/eslint_d/bin/eslint_d.js $modules/.bin/eslint_d
                ln -s $modules/eslint_d/bin/eslint.js $modules/.bin/eslint
              '';
            });
          };

          nodePackages_latest = prev.nodePackages_latest // _nodePackages_latest // {
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
            eslint = (_nodePackages_latest.eslint.override {
              dontNpmInstall = true;
              preRebuild = ''
                modules=$out/lib/node_modules
                mkdir -p $modules/.bin
                ln -s $modules/eslint/bin/eslint.js $modules/.bin/eslint
              '';
            });
            eslint_d = (_nodePackages_latest.eslint_d.override {
              dontNpmInstall = true;
              preRebuild = ''
                substituteInPlace bin/eslint_d.js --replace "'../lib/options'" "'../lib/options-cliengine'"
                modules=$out/lib/node_modules
                mkdir -p $modules/.bin
                ln -s $modules/eslint_d/bin/eslint_d.js $modules/.bin/eslint_d
                ln -s $modules/eslint_d/bin/eslint.js $modules/.bin/eslint
              '';
            });
            jsonlint = (_nodePackages_latest.jsonlint.override {
              dontNpmInstall = true;
              preRebuild = ''
                modules=$out/lib/node_modules
                mkdir -p $modules/.bin
                ln -s $modules/jsonlint/lib/cli.js $modules/.bin/jsonlint
              '';
            });
            node-pre-gyp = (_nodePackages_latest.node-pre-gyp.override {
              dontNpmInstall = true;
              preRebuild = ''
                modules=$out/lib/node_modules
                mkdir -p $modules/.bin
                ln -s $modules/node-pre-gyp/bin/node-pre-gyp $modules/.bin/node-pre-gyp
              '';
            });
            node-gyp = (_nodePackages_latest.node-gyp.override {
              dontNpmInstall = true;
              preRebuild = ''
                modules=$out/lib/node_modules
                mkdir -p $modules/.bin
                ln -s $modules/node-gyp/bin/node-gyp $modules/.bin/node-gyp
              '';
            });
            node-gyp-build = (_nodePackages_latest.node-gyp-build.override {
              dontNpmInstall = true;
              preRebuild = ''
                modules=$out/lib/node_modules
                mkdir -p $modules/.bin
                ln -s $modules/node-gyp-build/bin/node-gyp-build $modules/.bin/node-gyp-build
              '';
            });
            import-js = (_nodePackages_latest.import-js.override {
              dontNpmInstall = true;
              buildInputs = [ final.nodePackages_latest.node-pre-gyp ];
              preRebuild = ''
                modules=$out/lib/node_modules
                mkdir -p $modules/.bin
                ln -s $modules/import-js/bin/importjs.js $modules/.bin/importjs
                ln -s $modules/import-js/bin/importjsd.js $modules/.bin/importjsd
              '';
            });
            standardx = (_nodePackages_latest.standardx.override {
              dontNpmInstall = true;
              preRebuild = ''
                modules=$out/lib/node_modules
                mkdir -p $modules/.bin
                ln -s $modules/standardx/bin/standardx $modules/.bin/standardx
              '';
            });
            tslint = (_nodePackages_latest.tslint.override {
              dontNpmInstall = true;
              preRebuild = ''
                modules=$out/lib/node_modules
                mkdir -p $modules/.bin
                ln -s $modules/tslint/bin/tslint $modules/.bin/tslint
              '';
            });
            typescript = (_nodePackages_latest.typescript.override {
              dontNpmInstall = true;
              preRebuild = ''
                modules=$out/lib/node_modules
                mkdir -p $modules/.bin
                ln -s $modules/typescript/bin/tsc $modules/.bin/tsc
                ln -s $modules/typescript/bin/tsserver $modules/.bin/tsserver
              '';
            });
            testcafe-browser-tools = (_nodePackages_latest.testcafe-browser-tools.override {
              dontNpmInstall = true;
              preRebuild = ''
                modules=$out/lib/node_modules
                mkdir -p $modules/.bin
                ln -s $modules/testcafe-browser-tools/bin/ $modules/.bin/
              '';
            });
            trepan-ni = (_nodePackages_latest.trepan-ni.override {
              dontNpmInstall = true;
              preRebuild = ''
                modules=$out/lib/node_modules
                mkdir -p $modules/.bin
                ln -s $modules/trepan-ni/cli.js $modules/.bin/trepan-ni
                ln -s $modules/trepan-ni/cli.js $modules/.bin/cli.js
              '';
            });
          };
        };
    };
}
