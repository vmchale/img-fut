import imgfut

import imageio
import numpy as np
import scipy.ndimage

from matplotlib import pyplot as plt

mod = imgfut.imgfut()

img0 = np.array(imageio.imread('data/frog.png', pilmode='F'))

print ("processing...")
edges_img0 = mod.sobel_f32(img0)
blur_img0 = mod.mean_filter_f32(img0)
gauss_img0 = mod.gaussian_filter_f32(img0)
laplacian_img0 = mod.laplacian_filter_f32(img0)
gauss_img0_scipy = scipy.ndimage.gaussian_filter(img0, 3)
log_img0 = mod.laplacian_gaussian_filter_f32(img0)
print ("done processing...")

plt.gray()
plt.imshow(log_img0.get())
plt.show()
