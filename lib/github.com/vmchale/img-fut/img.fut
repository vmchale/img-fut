-- | Various image processing functions present in SciPy's [ndimage](https://docs.scipy.org/doc/scipy/reference/ndimage.html).

module type image_numeric = {

  type num

  -- | Linear transform of a grayscale image
  val matmul [m][n][p]: [n][m]num -> [m][p]num -> [n][p]num

  -- see https://hackage.haskell.org/package/hip-1.5.4.0/docs/Graphics-Image-Processing.html#t:Border
  type border = #edge | #reflect

  val with_window [m][n]: (k: i32) -> ([k][k]num -> num) -> [m][n]num -> [m][n]num
  -- TODO: reflect etc
  -- TODO: pixel type
  -- Look at colour-accelerate?

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

  val fft_mean_filter [m][n]: i32 -> [m][n]real -> [][]real

  val sobel [m][n]: [m][n]real -> [m][n]real

  val prewitt [m][n]: [m][n]real -> [m][n]real

  -- | 2-D Gaussian blur. The first argument `sigma` is the standard deviation.
  --
  -- See lecture notes [here](https://www.cs.auckland.ac.nz/courses/compsci373s1c/PatricesLectures/Gaussian%20Filtering_1up.pdf)
  val gaussian [m][n]: (sigma: real) -> (dim: i32) -> [m][n]real -> [m][n]real

  -- | Laplacian filter approximated by a 3x3 fiter.
  --
  -- See [this page](https://homepages.inf.ed.ac.uk/rbf/HIPR2/log.htm).
  val laplacian [m][n]: [m][n]real -> [m][n]real

  -- | See [here](https://homepages.inf.ed.ac.uk/rbf/HIPR2/log.htm) for reference.
  val laplacian_of_gaussian [m][n]: (sigma: real) -> (dim: i32) -> [m][n]real -> [m][n]real

}

module mk_image_numeric (M: numeric): (
  image_numeric with num = M.t
  ) = {

  type num = M.t

  type border = #edge | #reflect

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

  let correlate [ker_n] (ker: [ker_n][ker_n]M.t) =

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

  local import "../../diku-dk/fft/stockham-radix-2"
  module img_real = mk_image_numeric M
  module fft = mk_fft M

  type border = img_real.border

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

  local let conjugate_fft [k][l] (f: [k][l]real -> [k][l]real) : [k][l]real -> [][]real =
    let project_real [m][n] (xs: [m][n](real, real)) : [m][n]real =
      map (map (\(x, _) -> x)) xs
    in

    project_real <-< fft.ifft2_re <-< f <-< project_real <-< fft.fft2_re

  -- See [here](http://paulbourke.net/miscellaneous/imagefilter/)
  -- https://docs.scipy.org/doc/scipy/reference/generated/scipy.ndimage.fourier_gaussian.html
  let fft_mean_filter (n) =
    conjugate_fft(mean_filter n)

  -- see: http://hackage.haskell.org/package/hip-1.5.4.0/docs/Graphics-Image-Processing.html
  -- image rotations + reflections

  -- http://www.numerical-tours.com/matlab/denoisingadv_7_rankfilters/

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

  let laplacian =
    let ker: [3][3]M.t = [ [ M.from_fraction 0 1, M.from_fraction (-1) 1, M.from_fraction 0 1 ]
                         , [ M.from_fraction (-1) 1, M.from_fraction 4 1, M.from_fraction (-1) 1 ]
                         , [ M.from_fraction 0 1, M.from_fraction (-1) 1, M.from_fraction 0 1 ]
                         ]
    in correlate ker

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

  local let scale_2d (x) =
    let tot = M.sum (flatten x)
      in map (\x_row -> map (M./ tot) x_row) x

  let laplacian_of_gaussian(sigma)(dim) =
    let g_log(sigma: M.t)(x: M.t)(y: M.t): M.t =
      let one = M.from_fraction 1 1
      let two = M.from_fraction 2 1
      let four = M.from_fraction 4 1

      let rat = (x M.* x M.+ y M.* y) M./ (two M.* sigma M.* sigma)

      in M.negate (one M./ (M.pi M.* sigma M.** four)) M.* (one M.- rat) M.*
        M.exp (M.negate rat)

    -- TODO: maybe pick a fixed size? hm
    let log_kernel (sigma: M.t)(dim: i32): [dim][dim]M.t =
      -- let dim = 2 * radius + 1
      let radius = dim / 2
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

    correlate (log_kernel sigma dim)

  local let g_kernel (sigma: M.t)(dim: i32): [][]M.t =
    let g_gaussian(sigma: M.t)(x: M.t)(y: M.t): M.t =
      let one = M.from_fraction 1 1
      let two = M.from_fraction 2 1

      in (one M./ (two M.* M.pi M.* sigma M.* sigma)) M.*
        (M.exp (M.negate (x M.* x M.+ y M.* y) M./ (two M.* sigma M.* sigma)))

    -- TODO: even?
    let radius = dim / 2
    let pre_ker =
      tabulate_2d dim dim
        (\i j ->
          -- TODO: is this right?
          let i' = M.from_fraction (i - radius) 1
          let j' = M.from_fraction (j - radius) 1
          in g_gaussian sigma i' j')
    in

    scale_2d(pre_ker)

  let gaussian(sigma)(dim) =
    correlate (g_kernel sigma dim)

}
