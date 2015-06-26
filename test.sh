#!/bin/sh

RESULT=""

# Test each package we care about (dependencies will take care of themselves)
for pkg in ArbitraryHaskell hipspecifyer hipspec treefeatures HS2AST ml4hs mlspec AstPlugin
do
    RESULT="${RESULT}Testing $pkg: "
    if ./one.sh "$pkg"
    then
        RESULT="$RESULT PASS\n"
    else
        RESULT="$RESULT FAIL\n"
    fi
    echo -e "Results so far:\n$RESULT"
done
