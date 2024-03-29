-- | Various image processing functions present in SciPy's [ndimage](https://docs.scipy.org/doc/scipy/reference/ndimage.html).

module type image_numeric = {

  type num

  -- see https://hackage.haskell.org/package/hip-1.5.4.0/docs/Graphics-Image-Processing.html#t:Border
  type border = #edge | #reflect

  val with_window [m][n]: border -> (k: i64) -> ([k][k]num -> num) -> [m][n]num -> [m][n]num
  -- TODO: reflect etc
  -- TODO: pixel type
  -- Look at colour-accelerate?

  -- | This throws away pixels; it does no interpolation
  val ez_resize [m][n]: (k: i64) -> (l: i64) -> [m][n]num -> [k][l]num

  -- | This performs no interpolation; it simply throws away pixels
  val crop [m][n]: (k: i64) -> (l: i64) -> [m][n]num -> [k][l]num

  val maximum_filter [m][n]: border -> i64 -> [m][n]num -> [m][n]num

  val minimum_filter [m][n]: border -> i64 -> [m][n]num -> [m][n]num

  val maximum_2d [m][n]: [m][n]num -> num

  val minimum_2d [m][n]: [m][n]num -> num

  val correlate [m][n][p]: border -> [p][p]num -> [m][n]num -> [m][n]num

  -- | Kernel must be a square matrix; `p` must be odd.
  val convolve [m][n][p]: border -> [p][p]num -> [m][n]num -> [m][n]num

}

module type image_real = {

  include image_numeric

  type real

  val mean_filter [m][n]: border -> i64 -> [m][n]real -> [m][n]real

  val fft_mean_filter [m][n]: i64 -> [m][n]real -> [][]real

  val sobel [m][n]: border -> [m][n]real -> [m][n]real

  val prewitt [m][n]: border -> [m][n]real -> [m][n]real

  -- | 2-D Gaussian blur. The first argument `sigma` is the standard deviation.
  --
  -- See lecture notes [here](https://www.cs.auckland.ac.nz/courses/compsci373s1c/PatricesLectures/Gaussian%20Filtering_1up.pdf)
  val gaussian [m][n]: border -> (sigma: real) -> [m][n]real -> [m][n]real

  -- | Laplacian filter approximated by a 3x3 fiter.
  --
  -- See [this page](https://homepages.inf.ed.ac.uk/rbf/HIPR2/log.htm).
  val laplacian [m][n]: border -> [m][n]real -> [m][n]real

  -- | See [here](https://homepages.inf.ed.ac.uk/rbf/HIPR2/log.htm) for reference.
  val laplacian_of_gaussian [m][n]: border -> (sigma: real) -> [m][n]real -> [m][n]real

}

module type image_float = {

  include image_real

  type float

  -- | Median filter
  val median_filter [m][n]: border -> i64 -> [m][n]float -> [m][n]float

}
module mk_image_numeric (M: numeric): (
  image_numeric with num = M.t
  ) = {

  type num = M.t

  type border = #edge | #reflect

  local let window (row_start: i64) (col_start: i64) (row_end: i64) (col_end: i64) (x: [][]M.t) : [][]M.t =
    let ncols = col_end-col_start
    in map (\x_i -> x_i[col_start:col_end] :> [ncols]M.t) (x[row_start:row_end])

  let with_window_reflect [x_rows][x_cols] (ker_n)(f)(x: [x_rows][x_cols]M.t) =
    let extended_n = ker_n / 2

    let reflected =
      tabulate_2d (x_rows + ker_n - 1) (x_cols + ker_n - 1)
      (\i j ->
        let i' =
          if i <= extended_n then
            extended_n - i
          else
            if i + extended_n >= x_rows
              then x_rows - 1
              else i - extended_n
        let j' =
          if j <= extended_n then
            extended_n - j
          else
            if j + extended_n >= x_cols
              then
                x_cols - 1
                else j - extended_n
        in #[unsafe] (x[i'])[j'])
    in

    tabulate_2d x_rows x_cols
      (\i j ->
         let surroundings = window i j (i + ker_n) (j + ker_n) reflected
                            :> [ker_n][ker_n]M.t
        in
        f surroundings)

  let with_window_extended [x_rows][x_cols] (ker_n)(f)(x: [x_rows][x_cols]M.t) =
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
          in #[unsafe] (x[i'])[j'])
    in

    tabulate_2d x_rows x_cols
      (\i j ->
         let surroundings = window i j (i + ker_n) (j + ker_n) extended
                            :> [ker_n][ker_n]M.t
        in
        f surroundings)

  let with_window(scheme)(ker_n)(f)(x) =
    match scheme : border
      case #reflect -> with_window_reflect(ker_n)(f)(x)
      case #edge -> with_window_extended(ker_n)(f)(x)

  let maximum_2d =
    M.maximum <-< map M.maximum

  let minimum_2d =
    M.minimum <-< map M.minimum

  -- FIXME: these seem to be slow
  let maximum_filter (border)(sz) =
    with_window border sz maximum_2d

  let minimum_filter (border)(sz) =
    with_window border sz minimum_2d

  let matmul (x)(y) =
    map (\x_i ->
          map (\y_j -> M.sum (map2 (M.*) x_i y_j))
              (transpose y))
        x

  let correlate [ker_n] (scheme: border)(ker: [ker_n][ker_n]M.t) =

    let sum2(mat: [][]M.t) : M.t =
      M.sum (map (\x -> M.sum x) mat)

    let overlay_ker [n] (ker: [n][n]M.t) (slice: [n][n]M.t) : [n][n]M.t =
      tabulate_2d n n
        (\i j -> (ker[i])[j] M.* (slice[i])[j])

    in
    with_window scheme ker_n (\window -> sum2 (overlay_ker ker window))

  let convolve [p] (scheme: border)(ker: [p][p]M.t) =
    let flip x =
      tabulate_2d p p (\i j -> (x[p-i-1])[p-j-1])
    in

    correlate scheme (flip ker)

  let ez_resize (m)(n)(x) =
    let rows = length x
    let cols = length (head x)
    in

    tabulate_2d m n
      (\i j -> #[unsafe] (x[i * (rows / m)])[j * (cols / n)])

  let crop (i)(j)(x) =
    map (\x_i -> x_i[:j]) (x[:i])

}

-- TODO: mk_image_real for vectors as well (tuples &c.)
module mk_image_real (M: real): (
  image_real with real = M.t
  ) = {

  type num = M.t
  type real = M.t

  local import "../../diku-dk/fft/stockham-radix-2"
  module img_real = mk_image_numeric M
  module fft = mk_fft M

  type border = img_real.border

  let with_window = img_real.with_window
  let maximum_filter = img_real.maximum_filter
  let minimum_filter = img_real.minimum_filter
  let maximum_2d = img_real.maximum_2d
  let minimum_2d = img_real.minimum_2d
  let convolve = img_real.convolve
  let correlate = img_real.correlate
  let ez_resize = img_real.ez_resize
  let crop = img_real.crop

  let mean_filter (border)(ker_n) =
    let x_in = M.from_fraction 1 (ker_n * ker_n)
    let ker =
      tabulate_2d ker_n ker_n
        (\_ _ -> x_in)
    in

    convolve border ker

  local let conjugate_fft [m][n] (f: [m][n]real -> [m][n]real) : [m][n]real -> [m][n]real =
    let project_real (xs: [m][n](real, real)) : [m][n]real =
      map (map (\(x, _) -> x)) xs
    in

    project_real <-< fft.ifft2_re <-< f <-< project_real <-< fft.fft2_re

  -- See [here](http://paulbourke.net/miscellaneous/imagefilter/)
  -- https://docs.scipy.org/doc/scipy/reference/generated/scipy.ndimage.fourier_gaussian.html
  let fft_mean_filter (n) =
    conjugate_fft(mean_filter #edge n)

  -- see: http://hackage.haskell.org/package/hip-1.5.4.0/docs/Graphics-Image-Processing.html
  -- image rotations + reflections

  -- http://www.numerical-tours.com/matlab/denoisingadv_7_rankfilters/

  let sobel (border)(x) =
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

    in mag_intermed (convolve border g_x x) (convolve border g_y x)

  let laplacian (border) =
    let ker: [3][3]M.t = [ [ M.from_fraction 0 1, M.from_fraction (-1) 1, M.from_fraction 0 1 ]
                         , [ M.from_fraction (-1) 1, M.from_fraction 4 1, M.from_fraction (-1) 1 ]
                         , [ M.from_fraction 0 1, M.from_fraction (-1) 1, M.from_fraction 0 1 ]
                         ]
    in correlate border ker

  let prewitt (border)(x) =
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

    in mag_intermed (convolve border g_x x) (convolve border g_y x)

  local let scale_2d (x) =
    let tot = M.sum (flatten x)
      in map (\x_row -> map (M./ tot) x_row) x

  let laplacian_of_gaussian(border)(sigma) =
    let g_log(sigma: M.t)(x: M.t)(y: M.t): M.t =
      let one = M.from_fraction 1 1
      let two = M.from_fraction 2 1
      let four = M.from_fraction 4 1

      let rat = (x M.* x M.+ y M.* y) M./ (two M.* sigma M.* sigma)

      in M.neg (one M./ (M.pi M.* sigma M.** four)) M.* (one M.- rat) M.*
        M.exp (M.neg rat)

    let log_kernel =
      let three = M.from_fraction 3 1
      let radius = i64.max 1 (M.to_i64 (three M.* sigma))
      let dim = 2 * radius + 1
      let pre_ker =
        tabulate_2d dim dim
          (\i j ->
            let i' = M.from_fraction (i - radius) 1
            let j' = M.from_fraction (j - radius) 1
            in g_log sigma i' j')
      in

      -- trace?
      scale_2d(pre_ker)

    in

    correlate border log_kernel

  let gaussian(border)(sigma) =

    let g_gaussian(sigma: M.t)(x: M.t)(y: M.t): M.t =
      let one = M.from_fraction 1 1
      let two = M.from_fraction 2 1

      in (one M./ (two M.* M.pi M.* sigma M.* sigma)) M.*
        (M.exp (M.neg (x M.* x M.+ y M.* y) M./ (two M.* sigma M.* sigma)))

    let g_kernel =
      let three = M.from_fraction 3 1
      let radius = i64.max 1 (M.to_i64 (three M.* sigma))
      let dim = 2 * radius + 1
      let pre_ker =
        tabulate_2d dim dim
          (\i j ->
            -- TODO: is this right?
            let i' = M.from_fraction (i - radius) 1
            let j' = M.from_fraction (j - radius) 1
            in g_gaussian sigma i' j')
      in

      scale_2d(pre_ker)

    in

    correlate border g_kernel

}

module mk_image_float (M: float): (
  image_float with float = M.t
  ) = {

  local import "../../diku-dk/statistics/statistics"

  module img_numeric = mk_image_numeric M
  module img_float = mk_image_real M
  module statistics = mk_statistics M

  type num = M.t
  type real = M.t
  type float = M.t

  type border = img_numeric.border

  -- TODO: there's probably a better way to do this...
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
  let gaussian = img_float.gaussian
  let laplacian = img_float.laplacian
  let laplacian_of_gaussian = img_float.laplacian_of_gaussian
  let fft_mean_filter = img_float.fft_mean_filter

  -- | This is kind of slow.
  let median_filter (border)(n) =
    with_window border n (\x -> x |> flatten |> statistics.median)

}
