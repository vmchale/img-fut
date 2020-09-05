import "lib/github.com/vmchale/img-fut/img"

module img_f32 = mk_image_real f32
module img_f64 = mk_image_real f64

-- TODO: enumerate with #edge?
entry sobel_f32 = img_f32.sobel #reflect
entry sobel_f64 = img_f64.sobel #reflect

entry prewitt_f32 = img_f32.prewitt #reflect
entry prewitt_f64 = img_f64.prewitt #reflect

entry mean_filter_f32 = img_f32.mean_filter #reflect 7
entry mean_filter_f64 = img_f64.mean_filter #reflect 7

entry gaussian_filter_f32 = img_f32.gaussian #reflect 3
entry gaussian_filter_f64 = img_f64.gaussian #reflect 3

entry laplacian_filter_f32 = img_f32.laplacian #reflect
entry laplacian_filter_f64 = img_f64.laplacian #reflect

entry laplacian_gaussian_filter_f32 = img_f32.laplacian_of_gaussian #reflect 1.5
entry laplacian_gaussian_filter_f64 = img_f64.laplacian_of_gaussian #reflect 1.5

entry fft_mean_filter_f32 = img_f32.fft_mean_filter 5
entry fft_mean_filter_f64 = img_f64.fft_mean_filter 5
