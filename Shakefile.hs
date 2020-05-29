#!/usr/bin/env cabal
{- cabal:
build-depends: base, shake-futhark, shake
default-language: Haskell2010
ghc-options: -Wall -threaded -rtsopts "-with-rtsopts=-I0 -qg -qb"
-}

import           Development.Shake
import           Development.Shake.FilePath
import           Development.Shake.Futhark

main :: IO ()
main = shakeArgs shakeOptions { shakeFiles = ".shake", shakeLint = Just LintBasic, shakeChange = ChangeModtimeAndDigestInput } $ do
    want [ "imgfut.py" ]

    "clean" ~>
        command [] "rm" ["-rf", ".shake", "img", "img.c", "imgfut.py", "Pipfile.lock", "*.c", "*.c.h", "lib/github.com/diku-dk"]

    "imgfut.py" %> \out -> do
        need ["futhark.pkg"]
        let inp = "img-py.fut"
        needFut [inp]
        command [] "futhark" ["pyopencl", inp, "--library", "-o", dropExtension out]
