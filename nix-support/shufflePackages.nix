{ coreutils, pv, runScript, wget, withNix, writeScript }:
with builtins;

let listUrl     = "http://hackage.haskell.org/packages/index.tar.gz";

    packageList = runScript (withNix {}) ''
      set -e
      "${wget}/bin/wget" -O "index.tar.gz" "${listUrl}"
      RESULT=$(nix-store --add index.tar.gz)
      printf '%s' "$RESULT" > "$out"
    '';

    extractVersions = writeScript "extract-versions" ''
      PKG=""
      LATEST=""
      while read -r LINE
      do
        THIS_PKG=$(echo "$LINE" | cut -d / -f 1)
        if ! [[ "x$PKG" = "x$THIS_PKG" ]]
        then
          # Reached a new package; report the latest version of the last one
          [[ -z "$PKG" ]] || echo -e "$PKG\t$LATEST"

          # Start tracking this package instead
          PKG="$THIS_PKG"
        fi

        # Bump the latest version we've seen
        LATEST=$(echo "$LINE" | cut -d / -f 2)
      done < <("${pv}/bin/pv" -f < "${packageList}" | \
               tar -zt | grep -o '[^/][^/]*/[0-9][^/]*')

      echo -e "$PKG\t$LATEST"
    '';

    shuffled = runScript (withNix {}) ''
      set -e
      "${extractVersions}" | "${coreutils}/bin/uniq" | \
                             "${coreutils}/bin/shuf" > shuffled
      RESULT=$(nix-store --add shuffled)
      printf '%s' "$RESULT" > "$out"
    '';

    given = getEnv "SHUFFLED_LIST";
in if given == "" then shuffled else given