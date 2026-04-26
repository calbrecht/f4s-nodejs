{
  description = "Update node-packages.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages."${system}";

      nix_bin = pkgs.nix + /bin/nix;
      git_bin = pkgs.git + /bin/git;
    in
    {
      packages."${system}" = {
        commit-and-push = pkgs.writeScriptBin "commit-and-push" ''
          #!${pkgs.stdenv.shell}
          set -xeu

          user_name=''${git_user_name:-$(${git_bin} config user.name)}
          user_mail=''${git_user_mail:-$(${git_bin} config user.email)}

          test -z "$(${git_bin} status . -s)" && {
            : Nothing new, exiting.
            exit 0
          }

          ${git_bin} config user.name "$user_name"
          ${git_bin} config user.email "$user_mail"

          ${git_bin} add . >&2

          ${git_bin} commit -m "Update nodejs-tools" >&2
          ${git_bin} push >&2

          ${nix_bin} flake update --commit-lock-file
          ${git_bin} push >&2
        '';

        hash-update = pkgs.writeScriptBin "hash-update" ''
          #!${pkgs.stdenv.shell}
          set -xeu

          sed -i 's/nodejsToolsHash = [^;]\+;/nodejsToolsHash = lib.fakeHash;/' flake.nix
          sha=$(nix build .#nodejs-tools 2>&1 | grep got: | grep -oE 'sha.*')
          sed -i 's|nodejsToolsHash = [^;]\+;|nodejsToolsHash = "'"''${sha}"'";|' flake.nix
        '';

        auto-update = pkgs.writeScriptBin "auto-update" ''
          #!${pkgs.stdenv.shell}
          set -xeu

          ${nix_bin} run ./#pnpm -- up --latest && \
          . ${self.packages."${system}".hash-update}/bin/hash-update && true #\
          #. ${self.packages."${system}".commit-and-push}/bin/commit-and-push || \
          true
        '';
      };
    };
}
