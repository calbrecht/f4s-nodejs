{
  description = "Update node-packages.";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages."${system}";

      nix_bin = pkgs.nixFlakes + /bin/nix;
      git_bin = pkgs.git + /bin/git;
    in
    {
      packages."${system}" = {
        commit-and-push = pkgs.writeScriptBin "commit-and-push" ''
          #!${pkgs.stdenv.shell}
          set -xeu

          user_name=''${git_user_name:-$(${git_bin} config user.name)}
          user_mail=''${git_user_mail:-$(${git_bin} config user.email)}

          test -z "$(${git_bin} status pkgs -s)" && {
            : Nothing new, exiting.
            exit 0
          }

          ${git_bin} config user.name "$user_name"
          ${git_bin} config user.email "$user_mail"

          ${git_bin} add pkgs >&2

          ${git_bin} commit -m "Update node-packages" >&2
          ${git_bin} push >&2

          ${nix_bin} flake update --recreate-lock-file --commit-lock-file
          ${git_bin} push >&2
        '';

        auto-update = pkgs.writeScriptBin "auto-update" ''
          #!${pkgs.stdenv.shell}
          set -xeu

          ${nix_bin} run ./#node2nixup && \
          . ${self.packages."${system}".commit-and-push}/bin/commit-and-push || \
          true
        '';
      };
    };
}
