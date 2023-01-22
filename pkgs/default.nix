{pkgs, nodejs, stdenv }:

let
  nodePackages = import ./composition.nix {
    inherit pkgs nodejs;
    inherit (stdenv.hostPlatform) system;
  };
in
  nodePackages // {
    import-js = nodePackages.import-js.override (old: {
      buildInputs = old.buildInputs ++ [ nodePackages.node-pre-gyp ];
    });
    typescript-language-server = nodePackages.typescript-language-server.override (old: {
      buildInputs = old.buildInputs ++ [ nodePackages.typescript ];
    });
  }
