# Theory Exploration tools for Haskell; packaged for Nix
with import <nixpkgs> {};

# Allow package versions (git revisions) to be overridden, so we can reproduce
# old experiments
{
  # Haskell packages to use; eg. haskell.packages.ghc784 for GHC 7.8.4
  hsPkgs ? haskellPackages,

  hipspec ? {
    rev    = "19e11613fc";
    sha256 = "0m0kmkjn6w2h4d62swnhzj6la8041mvvcm2sachbng5hzkw6l8hf";
  },
  hipspecifyer ? {
    rev    = "f81eb6d630";
    sha256 = "1hb0mlds91fv3nxc0cppq48zfwcpkk5p2bmix75mmsnichkp8ncc";
  },
  treefeatures ? {
    sha256 = "1w71h7b1i91fdbxv62m3cbq045n1fdfp54h6bra2ccdj2snibx3y";
  },
  hs2ast ? {
    sha256 = "1lg8p0p30dp6pvbi007hlpxk1bnyxhfazzvgyqrx837da43ymm7f";
  },
  ml4hs ? {
    rev    = "2797f11";
    sha256 = "1q27a4ly1f5qqy18gs40ci01cvhxkahrhh6jighk60drprwv0fg1";
  },
  mlspec ? {
    rev    = "3ead342";
    sha256 = "04w3n080wwnfmpan1v9vc9g22zss6hx4jlwl6kraqpg64g5fjj78";
  },
  ArbitraryHaskell ? {
    rev    = "035ef80";
    sha256 = "0q3xv8bcxc7yvpv8pfk593q64z93bzs4aha85i2n4zivwn5xl10h";
  }
}:

# Define some helper functions

    # Lets us override cabal settings (haddock, tests, dependencies, etc.)
let hsTools = import "${<nixpkgs>}/pkgs/development/haskell-modules/lib.nix" {
      pkgs = import <nixpkgs> {};
    };

    # Generates a .nix file from a .cabal file, using the cabal2nix command
    # preConfig and preInstall are run before and after cabal2nix
    # cbl tells cabal2nix where to look (see cabal2nix documentation)
    nixFromCabal = {name, src, preConfig ? "", preInstall? "", cbl? "."}:
      stdenv.mkDerivation {
        inherit name src;
        buildInputs    = [ haskellPackages.cabal2nix ];
        configurePhase = ''
          (${preConfig}
           cabal2nix ${cbl} > default.nix)
        '';
        installPhase = ''
          (${preInstall}
           cp -r . "$out")
        '';
      };

    # Script to strip non-ASCII chars from .cabal files (they kill cabal2nix)
    asciifyCabal = ''
      for cbl in *.cabal
      do
        NAME=$(basename "$cbl" .cabal)
        mv "$cbl" "$NAME.nonascii"
        tr -cd '[:print:][:cntrl:]' < "$NAME.nonascii" > "$cbl"
      done
    '';

    # Merge or override defaults with given arguments
    mkSrc = given: defs: if (given ? sha256)
                         then fetchgit (defs // given)
                         else given;

# Return a set of packages which includes theory exploration tools
in (hsPkgs.override { overrides = (self: (super: {
  # DEPENDENCIES

  # We need < 0.16
  haskell-src-exts = self.callPackage (import ./haskell-src-exts.nix) {};

  # Hackage version is buggy
  structural-induction = hsTools.dontCheck (self.callPackage (nixFromCabal {
    name = "structural-induction-src";
    src  = fetchgit {
      url    = "https://github.com/danr/structural-induction.git";
      rev    = "f487a8225e";
      sha256 = "17f5v0xc9lh5505387qws8q2ffsga6435jqm0dgm9rmpx7429wbh";
    };
    preConfig = asciifyCabal;
  }) {});

  ArbitraryHaskell = self.callPackage (mkSrc ArbitraryHaskell {
    url = "http://chriswarbo.net/git/arbitrary-haskell.git";
  }) {};

  # THEORY EXPLORATION TOOLS (uses "//" to merge in version arguments)

  hipspec = self.callPackage (nixFromCabal {
    name = "hipspec-src";
    src  = mkSrc hipspec {
      name   = "hipspec-src";
      url    = https://github.com/danr/hipspec.git;
    };
    preConfig = asciifyCabal;
  }) {};

  hipspecifyer = self.callPackage (nixFromCabal {
    name = "hipspecifyer-src";
    src  = mkSrc hipspecifyer {
      url = https://github.com/moajohansson/IsaHipster.git;
    };
    # The cabal project lives in the "hipspecifyer" directory
    preConfig  = "cd hipspecifyer";
    preInstall = "cd hipspecifyer";
  }) {};

  treefeatures = self.callPackage (mkSrc treefeatures {
    name = "tree-features";
    url  = http://chriswarbo.net/git/tree-features.git;
  }) {};

  hs2ast = self.callPackage (mkSrc hs2ast {
    name = "hs2ast";
    url  = http://chriswarbo.net/git/hs2ast.git;
  }) {};

  ml4hs = (import (mkSrc ml4hs {
    name = "ml4hs";
    url  = http://chriswarbo.net/git/ml4hs.git;
  })) {
    treefeatures = self.treefeatures;
    hs2ast = self.hs2ast;
  };

  mlspec = self.callPackage (mkSrc mlspec {
    name   = "mlspec";
    url    = http://chriswarbo.net/git/mlspec.git;
  }) {};

})); })
