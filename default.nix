{ jq, jre, runCommand, stdenv, weka, writeScript }:

let cmd = writeScript "weka-cli" ''
      #!/usr/bin/env bash
      [[ -n "$JVM_MEM" ]] || export JVM_MEM="512M"
      "${jre}/bin/java" -Xmx"$JVM_MEM" -cp "${weka}/share/weka/weka.jar" "$@"
    '';
in stdenv.mkDerivation {
     name = "run-weka";

     # Exclude .git and test-data from being imported into the Nix store
     src = builtins.filterSource (path: type:
       baseNameOf path != ".git" &&
       baseNameOf path != "test-data") ./.;

     propagatedBuildInputs = [
       jq
       weka
       jre
     ];

     installPhase = ''
       mkdir -p "$out/bin"
       cp runWeka "$out/bin/"
       chmod +x "$out/bin/runWeka"

       cp ${cmd} "$out/bin/weka-cli"
     '';
   }
