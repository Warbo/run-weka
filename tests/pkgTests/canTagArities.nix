defs: with defs; pkg:

let arities = runScript (withNix { buildInputs = [ adb-scripts ]; }) ''
      set -e
      getArities < "${pkg.typeResults}" > arities.json
      "${storeResult}" arities.json "$out"
    '';

    arityTagged = runScript (withNix { buildInputs = [ adb-scripts ]; }) ''
      set -e
      tagAsts "${arities}" "{}" < "${pkg.dump}" > tagged.json
      "${storeResult}" tagged.json "$out"
    '';

    count = fromJSON (parseJSON (runScript {} ''
              "${jq}/bin/jq" -r 'length' < "${arityTagged}" > "$out"
            ''));
 in assertMsg (count > 0) "Found '${count}' tagged arities for '${pkg.name}'"