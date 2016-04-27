{ stdenv, jq, order-deps, ML4HSFE, nix, adb-scripts }:

stdenv.mkDerivation {
  name = "recurrent-clustering";

  # Exclude .git and test-data from being imported into the Nix store
  src = builtins.filterSource (path: type:
    baseNameOf path != ".git" &&
    baseNameOf path != "test-data") ./.;

  buildInputs = [ adb-scripts ];

  propagatedBuildInputs = [
    (import ./weka-cli.nix)
    order-deps
    ML4HSFE
    nix
    jq
  ];

  installPhase = ''
    mkdir -p "$out/bin"
    for FILE in recurrentClustering nix_recurrentClustering runWeka cluster
    do
        cp "$FILE" "$out/bin/"
    done

    mkdir -p "$out/lib"
    cp weka-cli.nix "$out/lib/"
    cp extractFeatures "$out/lib"

    chmod +x "$out/bin/"* "$out/lib/extractFeatures"
  '';
}
