-- Already done upstream!
module type field = {

  type element

  val add: element -> element -> element
  val multiply: element -> element -> element
  val zero: element
  val one: element
  val invert: element -> element
  val negate: element -> element

}

-- we only really care about real/complex vector spaces...
module type vector = {

  include field

  type vector

  val vect_add: vector -> vector -> vector
  val scalar_mult: element -> vector -> vector

}

module mk_field(M: real): (
  field with element = M.t
  ) = {

  type element = M.t

  -- the zero/one stuff is annoying
  let add = (M.+)
  let multiply = (M.*)
  let zero = M.from_fraction 0 1
  let one = M.from_fraction 1 1
  let invert (x) = one M./ x
  let negate(x) = M.negate x

}

-- | Make a 1-dimensional vector space from a real type
module mk_vector_numeric(M: real): (
  vector with vector = M.t
  ) = {


  module field = mk_field M

  type vector = M.t
  type element = field.element

  let multiply = field.multiply
  let zero = field.zero
  let one = field.one
  let add = field.add
  let invert = field.invert
  let negate = field.negate

  let vect_add = (M.+)
  let scalar_mult = (M.*)

}
