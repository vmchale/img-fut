#!/usr/bin/env cabal
{- cabal:
build-depends: base, shake-futhark, shake
default-language: Haskell2010
ghc-options: -Wall -threaded -rtsopts "-with-rtsopts=-I0 -qg -qb"
-}

import           Development.Shake
import           Development.Shake.FilePath
import           Development.Shake.Futhark

needInp :: Action ()
needInp = do
    need ["futhark.pkg"]
    needFut ["img-py.fut"]

main :: IO ()
main = shakeArgs shakeOptions { shakeFiles = ".shake", shakeLint = Just LintBasic, shakeChange = ChangeModtimeAndDigestInput } $ do
    want [ "imgfut.py" ]

    "clean" ~>
        command [] "rm" ["-rf", ".shake", "img", "img.c", "imgfut.py", "Pipfile.lock", "*.c", "*.c.h", "lib/github.com/diku-dk"]

    "Pipfile.lock" %> \_ ->
        command [] "pipenv" ["install"]

    "harness.py" %> \_ ->
        need ["Pipfile.lock", "imgfut.py"]

    "bench" ~> do
        need ["harness.py"]
        command [] "pipenv" ["run", "python", "harness.py"]

    "docs" ~>
        need ["docs/index.html"]

    "docs/index.html" %> \_ -> do
        needInp
        command [] "futhark" ["doc", "-o", "docs", "lib/github.com/vmchale/img-fut/img.fut"]

    "imgfut.py" %> \out -> do
        needInp
        let inp = "img-py.fut"
        command [] "futhark" ["pyopencl", inp, "--library", "-o", dropExtension out]
