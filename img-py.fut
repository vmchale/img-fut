import "img"

module img_f32 = mk_image f32
module img_f64 = mk_image f64

entry sobel_f32 = img_f32.sobel
-- entry sobel_f64 = img_f64.sobel

entry prewitt_f32 = img_f32.prewitt
-- entry prewitt_f64 = img_f64.prewitt

entry mean_filter_f32 = img_f32.mean_filter 7
-- entry mean_filter_f64 = img_f64.mean_filter 7

module img_f32_ext = mk_image_float f32
module img_f64_ext = mk_image_float f64

entry median_filter_f32 = img_f32_ext.median_filter 7
-- entry median_filter_f64 = img_f64_ext.median_filter 7
