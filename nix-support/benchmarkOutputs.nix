{ bc, dumpPackage, extractTarball, haskellPackages, lib, parseJSON, runScript }:
with lib;

let floatAdd         = x: y:
                         assert isString x;
                         assert isString y;
                         parseJSON (runScript { buildInputs = [ bc ]; } ''
                           echo 'scale=16; ${x} + ${y}' | bc
                         '');
    addTimes         = x: y: if y == null then x else {
                         mean = {
                           estPoint = floatAdd x.mean.estPoint y.mean.estPoint;
                         };
                       };
    addCriterion     = x: y: if y == null then x else floatAdd x y; # FIXME
    sumWithTime      = fold addTimes     null;
    sumWithCriterion = fold addCriterion null;
    processPkg       = name: pkg: rec {
      # Original Haskell fields
      inherit name pkg;
      src = extractTarball pkg.src;

      # AST dumps
      quickDump = dumpPackage { quick = true;  inherit src; };
      slowDump  = dumpPackage { quick = false; inherit src; };
      dump      = quickDump.stdout; # Stick to the quick output, arbitrarily

      # Total benchmark times
      totalWithTime      = sumWithTime      [ quickDump.time ];
      totalWithCriterion = sumWithCriterion [ slowDump.time  ];
    };
 in mapAttrs processPkg haskellPackages