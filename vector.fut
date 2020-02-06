module type vector = {

  -- TODO: include numeric instead?
  type scalar

  type vector

  val add: vector -> vector -> vector
  val scalar_mult: scalar -> vector -> vector

}

-- | Make a 1-dimensional vector space from a numeric type
module mk_vector_numeric(M: numeric): (
  vector with scalar = M.t with vector = M.t
  ) = {

  type scalar = M.t
  type vector = M.t

  let add = (M.+)
  let scalar_mult = (M.*)

}
