{ runScript, cabal-install, nix }:
pkgName:

# Try to download the given package from Hackage and add it to the Nix store.
# Since everything in $out will inherit all of this script's dependencies, the
# only thing we put in there is a path generated by 'nix-store --add', which
# depends only on the content of the Haskell package.

runScript {
    inherit pkgName;
    buildInputs = [ cabal-install nix ];

    # Required for invoking Nix recursively
    NIX_REMOTE = "daemon";
    NIX_PATH   = builtins.getEnv "NIX_PATH";
  }
  ''
    DELETEME=$(mktemp -d --tmpdir "download-to-nix-XXXXX")
    cd "$DELETEME"

    export HOME="$TMPDIR"
    cabal update
    cabal get "$pkgName" || exit 1
    for D in ./*
    # */
    do
      DIR=$(nix-store --add "$D")
      printf '%s' "$DIR" > "$out"
      break
    done
  ''
