module type color = {

  type real

  type pixel = (real, real, real)

  val luminance : pixel -> real

}

-- https://hackage.haskell.org/package/colour-accelerate-0.3.0.0/docs/src/Data.Array.Accelerate.Data.Colour.Names.html#NamedColour
-- https://github.com/athas/matte/blob/master/lib/github.com/athas/matte/colour.fut
-- https://github.com/nqpz/fut0r/blob/master/lib/github.com/nqpz/fut0r/filter/colorize.fut

module mk_module_numeric (N: real) : color = {

  type real = N.t

  type pixel = (real, real, real)

  let luminance (r, g, b)
    = (N.from_fraction 299 1000) N.* r N.+ (N.from_fraction 587 1000) N.*g N.+ (N.from_fraction 114 1000) N.* b

}
