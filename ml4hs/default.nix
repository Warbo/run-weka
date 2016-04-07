{ haskellPackages, jq, mlspec, stdenv }:

stdenv.mkDerivation {
  name = "ml4hs";
  src  = ./.;

  # Used for testing script
  propagatedBuildInputs = [
    jq
    (haskellPackages.ghcWithPackages (p: [
      p.QuickCheck
    ]))
    mlspec
  ];
  installPhase = ''
    # Put scripts in place
    mkdir -p "$out/lib/ml4hs"
    for SCRIPT in *.sh
    do
      cp "$SCRIPT" "$out/lib/ml4hs/"
    done
  '';
}
