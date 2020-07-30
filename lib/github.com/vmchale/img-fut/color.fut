module type color = {

  type real

  type pixel = (real, real, real)

  val luminance : pixel -> real

}

module mk_module_numeric (N: real) = {

  type real = N.t

  let luminance (r, g, b)
    = 0.299 *r + 0.587*g + 0.114*b -- TODO: parametric literals?

}
