defs: with defs; pkg:
with builtins;

let typeResults = runScript {} ''
      set -e
      "${jq}/bin/jq" -r '.result' < "${pkg.ranTypes}" \
                                  > typeResults.json
      "${storeResult}" typeResults.json "$out"
    '';

    arities = runScript { buildInputs = [ adb-scripts ]; } ''
      set -e
      getArities < "${typeResults}" > arities.json
      "${storeResult}" arities.json "$out"
    '';

    count = fromJSON (parseJSON (runScript {} ''
              "${jq}/bin/jq" -r 'length' < "${arities}" > "$out"
            ''));
 in testMsg (count > 0) "Found '${toString count}' arities for '${pkg.name}'"
