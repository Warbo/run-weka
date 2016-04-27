{ jq, jre, runCommand, stdenv, weka }:

let wekaCli = runCommand
  "weka-cli"
  { propagatedBuildInputs = [ jre weka ]; }
  ''
    # Make it easy to run Weka
    mkdir -p "$out/bin"
    cat <<'EOF' > "$out/bin/weka-cli"
    #!/usr/bin/env bash
    "${jre}/bin/java" -Xmx1000M -cp "${weka}/share/weka/weka.jar" "$@"
    EOF
    chmod +x "$out/bin/weka-cli"
  '';

in stdenv.mkDerivation {
     name = "run-weka";

     # Exclude .git and test-data from being imported into the Nix store
     src = builtins.filterSource (path: type:
       baseNameOf path != ".git" &&
       baseNameOf path != "test-data") ./.;

     propagatedBuildInputs = [
       wekaCli
       jq
     ];

     installPhase = ''
       mkdir -p "$out/bin"
       cp runWeka "$out/bin/"
       chmod +x "$out/bin/runWeka"
     '';
   }
