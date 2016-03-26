#! /usr/bin/env nix-shell
#! nix-shell -i bash -p jq

BASE=$(dirname "$0")

function msg {
    echo -e "$1" 1>&2
}

function abort {
    # Nope out
    msg "$*"
    exit 1
}

function fail {
    # Unconditional failure
    msg "FAIL $*"
    CODE=1
    return 1
}

# Test data

function build {
    nix-shell --run "cabal configure && cabal build" \
              -E "with import <nixpkgs> {}; import \"$GHCWITHPLUGIN\" \"$1\""
}

function buildable {
    # Test that the given package can be built normally; let alone with our
    # modifications
    F="$TESTDATA/$1.buildable"
    [[ ! -e "$F" ]] && {
        BUILDABLE=1  # Assume failure
        TMP="$TESTDATA/building"
        mkdir -p -v "$TMP"
        pushd "$TMP" > /dev/null
        FOUND=0
        shopt -s nullglob

        # shellcheck disable=SC2034
        for D in "$1"*
        do
            FOUND=1
        done

        if [[ "$FOUND" -eq 1 ]] || cabal get "$1"
        then
            if cd "$1"*
            then
                if _=$(build "$1" 2>&1) # Hide output, except for debugging
                then
                    BUILDABLE=0 # Success
                else
                    msg "Couldn't configure/build '$1'; see debug log"
                fi
            else
                msg "Couldn't cd to dir beginning with '$1'"
            fi
        else
            msg "Couldn't fetch '$1'"
        fi
        popd > /dev/null
        rm -r "$TMP"
        echo "$BUILDABLE" > "$F"
    }
    BUILDABLE=$(cat "$F")
    return "$BUILDABLE"
}

function ghcWithPlugin {
    if [[ -e "$BASE/ghcWithPlugin.nix" ]]
    then
        echo "$BASE/ghcWithPlugin.nix"
    elif [[ -e "$BASE/../lib/ghcWithPlugin.nix" ]]
    then
        echo "$BASE/../lib/ghcWithPlugin.nix"
    else
        fail "Didn't find ghcWithPlugin.nix in '$BASE' or '$BASE/../lib'"
        exit 1
    fi
}

function getRawJson {
    # Takes a package name, dumps its ASTs into $TESTDATA
    F="$TESTDATA/$1.rawjson"
    [[ ! -e "$F" ]] &&
        NOFORMAT="true" "$BASE/dump-hackage" "$1" > "$F"
    cat "$F"
}

function getRawAsts {
    # Takes a package name, dumps its ASTs into $TESTDATA
    F="$TESTDATA/$1.rawasts"
    [[ ! -e "$F" ]] &&
        "$BASE/dump-hackage" "$1" > "$F"
    cat "$F"
}

# Tests

function pkgTestGetRawJson {
    getRawJson "$1" | grep -c "^" > /dev/null ||
        fail "Couldn't get raw JSON from '$1'"
}

function pkgTestGetRawAsts {
    COUNT=$(getRawAsts "$1" | jq -r "length")
    [[ "$COUNT" -gt 0 ]] ||
        fail "Couldn't get raw ASTs from '$1'"
}

# Test running infrastructure

function getFunctions {
    # Get a list of the functions in this script
    declare -F | cut -d ' ' -f 3-
}

function getPkgTests {
    # Get a list of test functions which require a package
    getFunctions | grep '^pkgTest'
}

function getTests {
    # Get a list of all test functions
    getFunctions | grep '^test'

    TESTPKGS=$(getTestPkgs) || {
        fail "Problem getting list of packages to test, aborting"
        exit 1
    }

    [[ -n "$TESTPKGS" ]] || {
        fail "Wasn't able to find any working packages to test with, aborting"
        exit 1
    }

    # Apply each package test to each package
    while read -r pkg
    do
        while read -r test
        do
            echo "$test $pkg"
        done < <(getPkgTests)
    done < <(echo "$TESTPKGS")
}

function getTestPkgs {
    # These packages build for me, as of 2016-03-03
    for PKG in list-extras xmonad
    do
        if buildable "$PKG" 1>&2
        then
            msg "Tests will be run for '$PKG', as it is buildable"
            echo "$PKG"
        else
            msg "Skipping '$PKG' as it couldn't be built"
        fi
    done
}

function traceTest {
    # Separate our stderr from the previous and give a timestamp
    msg "\n\n"
    date 1>&2

    # Always set -x to trace tests, but remember our previous setting
    OLDDEBUG=0
    [[ "$-" == *x* ]] && OLDDEBUG=1

    set -x
    export SHELLOPTS
    "$@"; PASS=$?

    # Disable -x if it wasn't set before
    [[ "$OLDDEBUG" -eq 0 ]] && set +x

    return "$PASS"
}

function runTest {
    # Log stderr in $TESTDATA/debug. On failure, send "FAIL" and the debug
    # path to stdout
    read -ra CMD <<<"$@" # Re-parse our args to split packages from functions
    PTH=$(echo "$TESTDATA/debug/$*" | sed 's/ /_/g')
    traceTest "${CMD[@]}" 2>> "$PTH" || {
        cat "$PTH"
        fail "$* failed"
    }
}

function runTests {
    # Overall script exit code
    CODE=0

    # Set up directories, etc.
    init

    # Handle a regex, if we've been given one
    if [[ -z "$1" ]]
    then
        TESTS=$(getTests)
    else
        TESTS=$(getTests | grep "$1")
    fi

    while read -r test
    do
        # $test is either empty, successful or we're exiting with an error
        [[ -z "$test" ]] || runTest "$test" || CODE=1
    done < <(echo "$TESTS")

    # Remove directories, if necessary
    cleanup

    return "$CODE"
}

function init() {
    # Set the TESTDATA directory
    if [[ -n "$CABAL2DBTESTDIR" ]]
    then
        TMPDIR=""
        TESTDATA="$CABAL2DBTESTDIR/test-data"
    elif [[ -n "$XDG_CACHE_HOME" ]] && [[ -d "$XDG_CACHE_HOME" ]]
    then
        TMPDIR="$XDG_CACHE_HOME/cabal2db"
        TESTDATA="$TMPDIR/test-data"
    elif [[ -n "$HOME" ]] && [[ -d "$HOME" ]]
    then
        TMPDIR="$HOME/.cache/cabal2db"
        TESTDATA="$TMPDIR/test-data"
    else
        TMPDIR=$(mktemp -d -t 'cabal2db-test-XXXXX')
        TESTDATA="$TMPDIR/test-data"
    fi

    [[ -n "$TESTDATA" ]] ||
        abort "Error with test data dir"

    INITIAL=$(echo "$TESTDATA" | cut -c 1)
    [[ "x$INITIAL" = "x/" ]] ||
        abort "Test data dir '$TESTDATA' must be absolute"

    msg "Attempting to create test data dir '$TESTDATA'"
    mkdir -p "$TESTDATA/debug" ||
        abort "Couldn't make test data dir '$TESTDATA'"

    # Look for ghcWithPlugin.nix
    GHCWITHPLUGIN=$(readlink -f "$(ghcWithPlugin)")
}

function cleanup() {
    # Remove the TESTDATA directory, if we've been asked
    [[ -n "$CABAL2DBCLEANUP" ]] && {
        msg "Removing test data dir '$TESTDATA', as instructed"
        rm -r "$TESTDATA"
        [[ -n "$TMPDIR" ]] && {
            msg "Removing temp directory '$TMPDIR' as well"
            rmdir "$TMPDIR"
        }
    }
}

runTests "$1"
