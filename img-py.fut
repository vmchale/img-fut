import "lib/github.com/vmchale/img-fut/img"

module img_f32 = mk_image_real f32
module img_f64 = mk_image_real f64

entry sobel_f32 = img_f32.sobel
entry sobel_f64 = img_f64.sobel

entry prewitt_f32 = img_f32.prewitt
entry prewitt_f64 = img_f64.prewitt

entry mean_filter_f32 = img_f32.mean_filter 7
entry mean_filter_f64 = img_f64.mean_filter 7

entry gaussian_filter_f32 = img_f32.gaussian 3 19
entry gaussian_filter_f64 = img_f64.gaussian 3 19

entry laplacian_filter_f32 = img_f32.laplacian
entry laplacian_filter_f64 = img_f64.laplacian

entry laplacian_gaussian_filter_f32 = img_f32.laplacian_of_gaussian 1.5 6
entry laplacian_gaussian_filter_f64 = img_f64.laplacian_of_gaussian 1.5 6

entry fft_mean_filter_f32 = img_f32.fft_mean_filter 5
entry fft_mean_filter_f64 = img_f64.fft_mean_filter 5
