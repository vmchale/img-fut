-- | Various image processing functions present in SciPy's [ndimage](https://docs.scipy.org/doc/scipy/reference/ndimage.html).

-- other image types?
-- [3]u8
--
-- module type for vector spaces?

module type image_numeric = {

  type num

  -- | Linear transform of a grayscale image
  val matmul [m][n][p]: [n][m]num -> [m][p]num -> [n][p]num

  val with_window [m][n]: (k: i32) -> ([k][k]num -> num) -> [m][n]num -> [m][n]num
  -- TODO: reflect etc

  -- | This throws away pixels; it does no interpolation
  val ez_resize [m][n]: (k: i32) -> (l: i32) -> [m][n]num -> [k][l]num

  -- | This performs no interpolation; it simply throws away pixels
  val crop [m][n]: (k: i32) -> (l: i32) -> [m][n]num -> [k][l]num

  val maximum_filter [m][n]: i32 -> [m][n]num -> [m][n]num

  val minimum_filter [m][n]: i32 -> [m][n]num -> [m][n]num

  val maximum_2d [m][n]: [m][n]num -> num

  val minimum_2d [m][n]: [m][n]num -> num

  val correlate [m][n][p]: [p][p]num -> [m][n]num -> [m][n]num

  -- | Kernel must be a square matrix; `p` must be odd.
  val convolve [m][n][p]: [p][p]num -> [m][n]num -> [m][n]num

}

module type image_real = {

  include image_numeric

  type real

  val mean_filter [m][n]: i32 -> [m][n]real -> [m][n]real

  val sobel [m][n]: [m][n]real -> [m][n]real

  val prewitt [m][n]: [m][n]real -> [m][n]real

  -- TODO: gaussian filter!! -> gaussian "stencil" for a given sigma

}

module type image_float = {

  include image_real

  type float

  -- | Median filter
  val median_filter [m][n]: i32 -> [m][n]float -> [m][n]float

}

-- TODO: pixel type
-- Look at colour-accelerate?

module mk_image_numeric (M: numeric): (
  image_numeric with num = M.t
  ) = {

  type num = M.t

  let with_window [x_rows][x_cols] (ker_n)(f)(x: [x_rows][x_cols]M.t) =
    let extended_n = ker_n / 2

    -- extend it at the edges
    let extended =
      tabulate_2d (x_rows + ker_n - 1) (x_cols + ker_n - 1)
        (\i j ->
          let i' =
            if i <= extended_n then
              0
            else
              if i + extended_n >= x_rows
                then x_rows - 1
                else i - extended_n
          let j' =
            if j <= extended_n then
              0
            else
              if j + extended_n >= x_cols
                then x_cols - 1
                else j - extended_n
          in unsafe (x[i'])[j'])

    let window (row_start: i32) (col_start: i32) (row_end: i32) (col_end: i32) (x: [][]M.t) : [][]M.t =
      let ncols = col_end-col_start
      in map (\x_i -> x_i[col_start:col_end] :> [ncols]M.t) (x[row_start:row_end])

    in

    tabulate_2d x_rows x_cols
      (\i j ->
         let surroundings = window i j (i + ker_n) (j + ker_n) extended
                            :> [ker_n][ker_n]M.t
        in
        f surroundings)

  let maximum_2d =
    M.maximum <-< map M.maximum

  let minimum_2d =
    M.minimum <-< map M.minimum

  -- FIXME: these seem to be slow
  let maximum_filter (sz) =
    with_window sz maximum_2d

  let minimum_filter (sz) =
    with_window sz minimum_2d

  let matmul (x)(y) =
    map (\x_i ->
          map (\y_j -> M.sum (map2 (M.*) x_i y_j))
              (transpose y))
        x

  let correlate [ker_n] (ker: [][ker_n]M.t) =

    let sum2(mat: [][]M.t) : M.t =
      M.sum (map (\x -> M.sum x) mat)

    let overlay_ker [n] (ker: [n][n]M.t) (slice: [n][n]M.t) : [n][n]M.t =
      tabulate_2d n n
        (\i j -> (ker[i])[j] M.* (slice[i])[j])

    in
    with_window ker_n (\window -> sum2 (overlay_ker ker window))

  let convolve [p] (ker: [p][p]M.t) =
    let flip x =
      tabulate_2d p p (\i j -> (x[p-i-1])[p-j-1])
    in

    correlate (flip ker)

  let ez_resize (m)(n)(x) =
    let rows = length x
    let cols = length (head x)
    in

    tabulate_2d m n
      (\i j -> unsafe (x[i * (rows / m)])[j * (cols / n)])

  let crop (i)(j)(x) =
    map (\x_i -> x_i[:j]) (x[:i])

}

module mk_image_real (M: real): (
  image_real with real = M.t
  ) = {

  type num = M.t
  type real = M.t

  module img_real = mk_image_numeric M

  let with_window = img_real.with_window
  let maximum_filter = img_real.maximum_filter
  let minimum_filter = img_real.minimum_filter
  let maximum_2d = img_real.maximum_2d
  let minimum_2d = img_real.minimum_2d
  let matmul = img_real.matmul
  let convolve = img_real.convolve
  let correlate = img_real.correlate
  let ez_resize = img_real.ez_resize
  let crop = img_real.crop

  let mean_filter (ker_n) =
    let x_in = M.from_fraction 1 (ker_n * ker_n)
    let ker =
      tabulate_2d ker_n ker_n
        (\_ _ -> x_in)
    in

    convolve ker

  -- see: http://hackage.haskell.org/package/hip-1.5.4.0/docs/Graphics-Image-Processing.html
  -- image rotations + reflections (obviously)

  -- https://homepages.inf.ed.ac.uk/rbf/HIPR2/log.htm
  -- https://terpconnect.umd.edu/~toh/spectrum/FourierFilter.html
  -- https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4730687/
  -- http://www.numerical-tours.com/matlab/denoisingadv_7_rankfilters/

  -- https://reinvantveer.github.io/2019/07/12/elliptical_fourier_analysis.html

  -- https://homepages.inf.ed.ac.uk/rbf/HIPR2/gsmooth.htm

  -- https://github.com/diku-dk/fft for FFT stuff

  -- See for Gaussian: https://github.com/scipy/scipy/blob/master/scipy/ndimage/filters.py#L160

  let sobel (x) =
    let g_x: [3][3]M.t = [ [ M.from_fraction (-1) 1, M.from_fraction 0 1, M.from_fraction 1 1 ]
                         , [ M.from_fraction (-2) 1, M.from_fraction 0 1, M.from_fraction 2 1 ]
                         , [ M.from_fraction (-1) 1, M.from_fraction 0 1, M.from_fraction 1 1 ]
                         ]

    let g_y: [3][3]M.t = [ [ M.from_fraction (-1) 1, M.from_fraction (-2) 1, M.from_fraction (-1) 1 ]
                         , [ M.from_fraction 0 1, M.from_fraction 0 1, M.from_fraction 0 1 ]
                         , [ M.from_fraction 1 1, M.from_fraction 2 1, M.from_fraction 1 1 ]
                         ]

    let mag_intermed [m][n] (x: [m][n]M.t) (y: [m][n]M.t) : [m][n]M.t =
      tabulate_2d m n
        (\i j -> M.sqrt ((x[i])[j] M.* (x[i])[j] M.+ (y[i])[j] M.* (y[i])[j]))

    in mag_intermed (convolve g_x x) (convolve g_y x)

  let prewitt (x) =
    let g_x: [3][3]M.t = [ [ M.from_fraction 1 1, M.from_fraction 0 1, M.from_fraction (-1) 1 ]
                         , [ M.from_fraction 1 1, M.from_fraction 0 1, M.from_fraction (-1) 1 ]
                         , [ M.from_fraction 1 1, M.from_fraction 0 1, M.from_fraction (-1) 1 ]
                         ]

    let g_y: [3][3]M.t = [ [ M.from_fraction 1 1, M.from_fraction 1 1, M.from_fraction 1 1 ]
                         , [ M.from_fraction 0 1, M.from_fraction 0 1, M.from_fraction 0 1 ]
                         , [ M.from_fraction (-1) 1, M.from_fraction (-1) 1, M.from_fraction (-1) 1 ]
                         ]

    let mag_intermed [m][n] (x: [m][n]M.t) (y: [m][n]M.t) : [m][n]M.t =
      tabulate_2d m n
        (\i j -> M.sqrt ((x[i])[j] M.* (x[i])[j] M.+ (y[i])[j] M.* (y[i])[j]))

    in mag_intermed (convolve g_x x) (convolve g_y x)

}

module mk_image_float (M: float): (
  image_float with float = M.t
  ) = {

  local import "lib/github.com/diku-dk/statistics/statistics"

  module img_numeric = mk_image_numeric M
  module img_float = mk_image_real M
  module statistics = mk_statistics M

  type num = M.t
  type real = M.t
  type float = M.t

  -- TODO: there's probably a better way to do this...
  let matmul = img_numeric.matmul
  let correlate = img_numeric.correlate
  let convolve = img_numeric.convolve
  let sobel = img_float.sobel
  let prewitt = img_float.prewitt
  let mean_filter = img_float.mean_filter
  let maximum_filter = img_numeric.maximum_filter
  let minimum_filter = img_numeric.minimum_filter
  let with_window = img_numeric.with_window
  let maximum_2d = img_numeric.maximum_2d
  let minimum_2d = img_numeric.minimum_2d
  let ez_resize = img_numeric.ez_resize
  let crop = img_numeric.crop

  -- see: https://www.cs.auckland.ac.nz/courses/compsci373s1c/PatricesLectures/Gaussian%20Filtering_1up.pdf
  local let g_gaussian(sigma: M.t)(x: M.t)(y: M.t): M.t =
    let one = M.from_fraction 1 1
    let two = M.from_fraction 2 1

    in (one M./ (two M.* M.pi M.* sigma M.* sigma)) M.*
      (M.exp (M.negate (x M.* x M.+ y M.* y) M./ (two M.* sigma M.* sigma)))
      -- also look at: https://github.com/scipy/scipy/blob/adc4f4f7bab120ccfab9383aba272954a0a12fb0/scipy/ndimage/filters.py#L136

  -- | This is kind of slow.
  let median_filter (n) = with_window n (statistics.median <-< flatten)

}
