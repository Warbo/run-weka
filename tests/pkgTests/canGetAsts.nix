defs: with defs; pkg:
with builtins;

let count = fromJSON (parseJSON (runScript {} ''
      "${jq}/bin/jq" -r 'length' < "${pkg.preAnnotated}" > "$out"
    ''));
 in testMsg (count > 0)
            "Found '${toString count}' pre-annotated ASTs for '${pkg.name}'"
