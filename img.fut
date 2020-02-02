-- | Various image processing functions present in SciPy's [ndimage](https://docs.scipy.org/doc/scipy/reference/ndimage.html).


-- TODO: only need float for median...
module image (M: real) = {

  -- see: http://hackage.haskell.org/package/hip-1.5.4.0/docs/Graphics-Image-Processing.html
  -- image rotations + reflections (obviously)

  -- | Linear transform of an image
  let matmul [n][m][p] (x: [n][m]M.t) (y: [m][p]M.t) : [n][p]M.t =
    map (\x_i ->
          map (\y_j -> M.sum (map2 (M.*) x_i y_j))
              (transpose y))
        x

  -- | Throw away a bunch of points so it's the right size.
  let ez_resize (m: i32) (n: i32) (x: [][]M.t) : [m][n]M.t =
    let rows = length x
    let cols = length (head x)
    in

    tabulate_2d m n
      (\i j -> unsafe (x[i * (rows / m)])[j * (cols / n)])

  -- | Crop an image by ignoring the other bits
  let crop [m][n] (i: i32) (j: i32) (x: [m][n]M.t) : [i][j]M.t =
    map (\x_i -> x_i[:j]) (x[:i])

  let with_window [m][n] (ker_n: i32)(f: [][]M.t -> M.t)(x: [m][n]M.t) : [m][n]M.t =
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

  -- FIXME: these seem to be slow
  let maximum_filter [m][n] (sz: i32)(x: [m][n]M.t) : [m][n]M.t =
    let maximum_2d [p] (x: [p][p]M.t) : M.t =
      M.maximum (map M.maximum x)
    in
    with_window sz maximum_2d x

  let minimum_filter [m][n] (sz: i32)(x: [m][n]M.t) : [m][n]M.t =
    let minimum_2d [p] (x: [p][p]M.t) : M.t =
      M.minimum (map M.minimum x)
    in
    with_window sz minimum_2d x

  let correlate [m][n][p] (ker: [p][p]M.t)(x: [m][n]M.t) : [m][n]M.t =

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

  let convolve [m][n][p] (ker: [p][p]M.t)(x: [m][n]M.t) : [m][n]M.t =
    let flip [n] (x: [n][n]M.t) : [n][n]M.t =
      let l = length x

      in tabulate_2d l l
        (\i j -> (x[l-i-1])[l-j-1])
    in

    correlate (flip ker) x

  let mean_filter [m][n] (ker_n: i32) (x: [m][n]M.t) : [m][n]M.t =
    let x_in = M.from_fraction 1 (ker_n * ker_n)
    let ker =
      tabulate_2d ker_n ker_n
        (\_ _ -> x_in)
    in

    convolve ker x

  let sobel [m][n] (x: [m][n]M.t) : [m][n]M.t =
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

  let prewitt [m][n] (x: [m][n]M.t) : [m][n]M.t =
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

-- TODO: module types? figure out
module image_float (M: float) = {

  local import "lib/github.com/diku-dk/sorts/radix_sort"

  local let median (x: []M.t) : M.t =
    let sort : []M.t -> []M.t =
      radix_sort_float M.num_bits M.get_bit
    let sorted = sort x
    let n = length x
    in

    if n % 2 == 0
      then (sorted[n/2 - 1] M.+ sorted[n/2]) M./ (M.from_fraction 2 1)
      else sorted[n/2]

}
