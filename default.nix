{ jq, jre, makeWrapper, perl, runCommand, stdenv, weka, writeScript }:

stdenv.mkDerivation {
  inherit jq jre perl weka;

  name        = "run-weka";
  buildInputs = [ makeWrapper ];

  src = ./runWeka;
  cmd = writeScript "weka-cli" ''
    #!/usr/bin/env bash
    java $JVM_OPTS -cp "$WEKA/share/weka/weka.jar" "$@"
  '';

  unpackPhase  = "true";  # Nothing to unpack
  installPhase = ''
    mkdir -p "$out/bin"

    makeWrapper "$src" "$out/bin/runWeka" \
      --prefix PATH : "$jq/bin"           \
      --prefix PATH : "$weka/bin"         \
      --prefix PATH : "$jre/bin"          \
      --prefix PATH : "$perl/bin"

    makeWrapper "$cmd" "$out/bin/weka-cli" \
      --prefix PATH : "$jre/bin" \
      --set    WEKA   "$weka"
  '';
}
