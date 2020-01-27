module perceptual_hash (M: float) = {

  local import "lib/github.com/diku-dk/sorts/radix_sort"

  local let matmul [n][m][p] (x: [n][m]M.t) (y: [m][p]M.t) : [n][p]M.t =
    map (\x_i ->
          map (\y_j -> M.sum (map2 (M.*) x_i y_j))
              (transpose y))
        x

  local let median (x: []M.t) : M.t =
    let sort : []M.t -> []M.t =
      radix_sort_float M.num_bits M.get_bit
    let sorted = sort x
    let n = length x
    in

    if n % 2 == 0
      then (sorted[n/2 - 1] M.+ sorted[n/2]) M./ (M.from_fraction 2 1)
      else sorted[n/2]

  let mean_filter [m][n] (ker_n: i32, x: [m][n]M.t) : [m][n]M.t =
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

    in extended


  -- TODO: convolve
}
