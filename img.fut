-- | Various image processing functions present in SciPy's [ndimage](https://docs.scipy.org/doc/scipy/reference/ndimage.html).

module type image_numeric = {

  type num

  -- | Linear transform of a grayscale image
  val matmul [m][n][p]: [n][m]num -> [m][p]num -> [n][p]num

  val with_window [m][n]: (k: i32) -> ([k][k]num -> num) -> [m][n]num -> [m][n]num

  -- | This just throws away some pixels; it does not do any interpolation
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

}

module type image_float = {

  include image_real

  type float

  -- | Median filter
  val median_filter [m][n]: i32 -> [m][n]float -> [m][n]float

}

module mk_image_numeric (M: numeric): (
  image_numeric with num = M.t
  ) = {

  type num = M.t

  let with_window (ker_n)(f)(x) =
    let x_rows = length x
    let x_cols = length (head x)

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
      map (\x_i -> x_i[col_start:col_end]) (x[row_start:row_end])

    in

    tabulate_2d x_rows x_cols
      (\i j ->
        let surroundings = window i j (i + ker_n) (j + ker_n) extended
        in
        f surroundings)

  let maximum_2d (x) =
    M.maximum (map M.maximum x)

  let minimum_2d (x) =
    M.minimum (map M.minimum x)

  -- FIXME: these seem to be slow
  let maximum_filter (sz)(x) =
    with_window sz maximum_2d x

  let minimum_filter (sz)(x) =
    with_window sz minimum_2d x

  let matmul (x)(y) =
    map (\x_i ->
          map (\y_j -> M.sum (map2 (M.*) x_i y_j))
              (transpose y))
        x

  let correlate (ker)(x) =

    let ker_n = length (head ker)

    let sum2(mat: [][]M.t) : M.t =
      M.sum (map (\x -> M.sum x) mat)

    let overlay_ker [n] (ker: [n][n]M.t) (slice: [n][n]M.t) : [n][n]M.t =
      let dim_x = length slice
      let dim_y = length (head slice)
      in

      tabulate_2d dim_x dim_y
        (\i j -> (ker[i])[j] M.* (slice[i])[j])

    in
    with_window ker_n (\window -> sum2 (overlay_ker ker window)) x

  let convolve (ker)(x) =
    let flip [n] (x: [n][n]M.t) : [n][n]M.t =
      let l = length x

      in tabulate_2d l l
        (\i j -> (x[l-i-1])[l-j-1])
    in

    correlate (flip ker) x

  let ez_resize (m)(n)(x) =
    let rows = length x
    let cols = length (head x)
    in

    tabulate_2d m n
      (\i j -> unsafe (x[i * (rows / m)])[j * (cols / n)])

  -- | Crop an image by ignoring the other bits
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

  let mean_filter [m][n] (ker_n: i32) (x: [m][n]M.t) : [m][n]M.t =
    let x_in = M.from_fraction 1 (ker_n * ker_n)
    let ker =
      tabulate_2d ker_n ker_n
        (\_ _ -> x_in)
    in

    convolve ker x

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
      let rows = length x
      let cols = length (head x)

      in tabulate_2d rows cols
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
      let rows = length x
      let cols = length (head x)

      in tabulate_2d rows cols
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

  local let median =
    statistics.median

  -- | This is kind of slow.
  let median_filter (n)(x) = with_window n (\arr -> median (flatten arr)) x

}
